`timescale 1ns / 1ps

module osr_tb;

localparam real CLK_PERIOD = 325.52;
localparam real FS_ADC     = 3072000.0;
localparam real PI2        = 6.283185307179586;

localparam [1:0] MODE_NB  = 2'd0;
localparam [1:0] MODE_WB  = 2'd1;
localparam [1:0] MODE_SWB = 2'd2;

localparam integer AMP_M3DBFS = 1449;
localparam integer MAX_ADC_PER_FREQ = 4000000;

reg         clk;
reg         rst_n;
reg         eoc;
reg  [11:0] adc_data;
reg  [1:0]  mode;
reg  signed [3:0]  dga_shift;
reg  [16:0] dga_frac_q16;
wire signed [15:0] data_out;
wire        data_valid;

osr_top u_dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .eoc           (eoc),
    .adc_data      (adc_data),
    .mode          (mode),
    .dga_shift     (dga_shift),
    .dga_frac_q16  (dga_frac_q16),
    .data_out      (data_out),
    .data_valid    (data_valid)
);

initial clk = 1'b0;
always #(CLK_PERIOD/2.0) clk = ~clk;

integer overflow_count;

always @(posedge clk) begin
    if (data_valid) begin
        if (u_dut.u_hpf.y_raw > 18'sd32767 || u_dut.u_hpf.y_raw < -18'sd32768)
            overflow_count = overflow_count + 1;
    end
end

task configure_mode(input [1:0] m);
begin
    mode = m;
    case (m)
        MODE_NB: begin
            dga_shift     = -4'sd3;
            dga_frac_q16  = 17'd130637;
        end
        MODE_WB: begin
            dga_shift     = -4'sd3;
            dga_frac_q16  = 17'd130828;
        end
        default: begin
            dga_shift     = -4'sd2;
            dga_frac_q16  = 17'd65672;
        end
    endcase
end
endtask

task configure_mode_headroom(input [1:0] m);
begin
    mode = m;
    case (m)
        MODE_NB: begin
            dga_shift     = -4'sd4;
            dga_frac_q16  = 17'd122953;
        end
        MODE_WB: begin
            dga_shift     = -4'sd4;
            dga_frac_q16  = 17'd123133;
        end
        default: begin
            dga_shift     = -4'sd4;
            dga_frac_q16  = 17'd123619;
        end
    endcase
end
endtask

task do_reset;
begin
    rst_n    = 1'b0;
    eoc      = 1'b0;
    adc_data = 12'd0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
end
endtask

task push_adc_sample(input integer amplitude, input real freq, input integer idx);
begin
    @(negedge clk);
    begin : gen_samp
        real sv;
        integer q;
        sv = $sin(PI2 * freq * $itor(idx) / FS_ADC);
        q  = $rtoi(sv * $itor(amplitude));
        if (q >  2047) q =  2047;
        if (q < -2048) q = -2048;
        adc_data = q[11:0];
    end
    eoc = 1'b1;
    @(negedge clk);
    eoc = 1'b0;
    @(posedge clk);
end
endtask

task run_thdn(input [1:0] m, input string mname);
    integer f, adc_cnt, skip_cnt, cap_cnt;
    reg signed [15:0] thdn_pk_pos, thdn_pk_neg;
begin
    $display("  THD+N %s: 1kHz @ -3dBFS ...", mname);
    configure_mode(m);
    do_reset();
    overflow_count = 0;

    f = $fopen({"results/thdn_", mname, ".txt"}, "w");

    skip_cnt = 0;
    cap_cnt  = 0;
    thdn_pk_pos = -16'sd32768;
    thdn_pk_neg =  16'sd32767;

    for (adc_cnt = 0; adc_cnt < MAX_ADC_PER_FREQ && cap_cnt < 4096; adc_cnt = adc_cnt + 1) begin
        push_adc_sample(AMP_M3DBFS, 1000.0, adc_cnt);
        if (data_valid) begin
            if (skip_cnt < 512)
                skip_cnt = skip_cnt + 1;
            else begin
                $fwrite(f, "%0d\n", $signed(data_out));
                if ($signed(data_out) > thdn_pk_pos) thdn_pk_pos = $signed(data_out);
                if ($signed(data_out) < thdn_pk_neg) thdn_pk_neg = $signed(data_out);
                cap_cnt = cap_cnt + 1;
            end
        end
    end

    repeat (4000) @(posedge clk) begin
        if (data_valid && cap_cnt < 4096) begin
            if (skip_cnt < 512)
                skip_cnt = skip_cnt + 1;
            else begin
                $fwrite(f, "%0d\n", $signed(data_out));
                if ($signed(data_out) > thdn_pk_pos) thdn_pk_pos = $signed(data_out);
                if ($signed(data_out) < thdn_pk_neg) thdn_pk_neg = $signed(data_out);
                cap_cnt = cap_cnt + 1;
            end
        end
    end

    $fclose(f);
    $display("    captured=%0d  ovf=%0d  pk+=%0d  pk-=%0d",
             cap_cnt, overflow_count, thdn_pk_pos, thdn_pk_neg);
end
endtask

integer total_pass, total_fail;

localparam integer FREQRESP_MEAS_CNT = 1024;
localparam integer FREQRESP_SKIP_CNT = 4096;

// Passband limits (dB re 1 kHz). Points outside passband are not checked.
// NB passband: 300–3200 Hz, ±3 dB
// WB passband: 200–6400 Hz, ±3 dB
// SWB passband: 200–12000 Hz, ±3 dB
localparam real PASSBAND_TOL_DB = 3.0;

task run_freq_sweep(input [1:0] m, input string mname);
    integer sf, fi, adc_cnt, skip_cnt, meas_cnt;
    integer freq_list [0:14];
    integer num_freqs;
    reg signed [15:0] pk_pos, pk_neg;
    integer amp_out;
    integer amp_arr [0:14];
    integer amp_1k;
    integer pb_lo, pb_hi;
    integer n_fail;
    real gain_db;
begin
    case (m)
        MODE_NB: begin
            num_freqs = 12;
            freq_list[0]  = 100;  freq_list[1]  = 150;  freq_list[2]  = 200;
            freq_list[3]  = 300;  freq_list[4]  = 500;  freq_list[5]  = 1000;
            freq_list[6]  = 1400; freq_list[7]  = 2000; freq_list[8]  = 2800;
            freq_list[9]  = 3000; freq_list[10] = 3200; freq_list[11] = 3400;
            pb_lo = 300; pb_hi = 3200;
        end
        MODE_WB: begin
            num_freqs = 13;
            freq_list[0]  = 100;  freq_list[1]  = 150;  freq_list[2]  = 200;
            freq_list[3]  = 300;  freq_list[4]  = 500;  freq_list[5]  = 1000;
            freq_list[6]  = 2000; freq_list[7]  = 3000; freq_list[8]  = 4000;
            freq_list[9]  = 5000; freq_list[10] = 6000; freq_list[11] = 6400;
            freq_list[12] = 6700;
            pb_lo = 200; pb_hi = 6400;
        end
        default: begin
            num_freqs = 14;
            freq_list[0]  = 100;  freq_list[1]  = 150;  freq_list[2]  = 200;
            freq_list[3]  = 300;  freq_list[4]  = 500;  freq_list[5]  = 1000;
            freq_list[6]  = 2000; freq_list[7]  = 4000; freq_list[8]  = 6000;
            freq_list[9]  = 8000; freq_list[10] = 10000; freq_list[11] = 11000;
            freq_list[12] = 12000; freq_list[13] = 14000;
            pb_lo = 200; pb_hi = 12000;
        end
    endcase

    sf = $fopen({"results/freqresp_", mname, ".txt"}, "w");
    $fwrite(sf, "freq_hz,amplitude,overflows\n");

    amp_1k = 0;
    n_fail = 0;

    for (fi = 0; fi < num_freqs; fi = fi + 1) begin
        configure_mode(m);
        do_reset();
        overflow_count = 0;

        pk_pos = -16'sd32768;
        pk_neg =  16'sd32767;
        skip_cnt = 0;
        meas_cnt = 0;

        for (adc_cnt = 0; adc_cnt < MAX_ADC_PER_FREQ && meas_cnt < FREQRESP_MEAS_CNT; adc_cnt = adc_cnt + 1) begin
            push_adc_sample(AMP_M3DBFS, $itor(freq_list[fi]), adc_cnt);
            if (data_valid) begin
                if (skip_cnt < FREQRESP_SKIP_CNT)
                    skip_cnt = skip_cnt + 1;
                else begin
                    if ($signed(data_out) > pk_pos) pk_pos = $signed(data_out);
                    if ($signed(data_out) < pk_neg) pk_neg = $signed(data_out);
                    meas_cnt = meas_cnt + 1;
                end
            end
        end

        repeat (4000) @(posedge clk) begin
            if (data_valid && meas_cnt < FREQRESP_MEAS_CNT) begin
                if (skip_cnt < FREQRESP_SKIP_CNT)
                    skip_cnt = skip_cnt + 1;
                else begin
                    if ($signed(data_out) > pk_pos) pk_pos = $signed(data_out);
                    if ($signed(data_out) < pk_neg) pk_neg = $signed(data_out);
                    meas_cnt = meas_cnt + 1;
                end
            end
        end

        amp_out = (pk_pos - pk_neg) / 2;
        amp_arr[fi] = amp_out;
        $fwrite(sf, "%0d,%0d,%0d\n", freq_list[fi], amp_out, overflow_count);

        if (freq_list[fi] == 1000) amp_1k = amp_out;

        $display("    %s %0d Hz: amp=%0d  ovf=%0d  meas=%0d",
                 mname, freq_list[fi], amp_out, overflow_count, meas_cnt);
    end

    $fclose(sf);

    if (amp_1k > 0) begin
        $display("    %s passband check (±%.1f dB re 1kHz=%0d, %0d–%0d Hz):",
                 mname, PASSBAND_TOL_DB, amp_1k, pb_lo, pb_hi);
        for (fi = 0; fi < num_freqs; fi = fi + 1) begin
            if (freq_list[fi] >= pb_lo && freq_list[fi] <= pb_hi && amp_arr[fi] > 0) begin
                gain_db = 20.0 * $ln($itor(amp_arr[fi]) / $itor(amp_1k)) / $ln(10.0);
                if (gain_db > PASSBAND_TOL_DB || gain_db < -PASSBAND_TOL_DB) begin
                    $display("      %0d Hz: %.1f dB FAIL", freq_list[fi], gain_db);
                    n_fail = n_fail + 1;
                end else begin
                    $display("      %0d Hz: %.1f dB ok", freq_list[fi], gain_db);
                end
            end
        end
    end

    if (n_fail == 0) begin
        $display("  [PASS] Freq response %s", mname);
        total_pass = total_pass + 1;
    end else begin
        $display("  [FAIL] Freq response %s: %0d points outside ±%.1f dB",
                 mname, n_fail, PASSBAND_TOL_DB);
        total_fail = total_fail + 1;
    end
end
endtask

// Expected output amplitude at 1 kHz / -3 dBFS for each mode.
// -3 dBFS input = 1449 codes.  Expected output pk after DGA:
//   NB:  ~17293 (-5.5 dBFS — known ~2.5 dB gain error, issue #18)
//   WB:  ~16620 (-5.9 dBFS — known ~2.9 dB gain error, issue #18)
//   SWB: ~22594 (-3.2 dBFS — close to expected)
// AMP_TOL_DB: allowed deviation from measured baseline (not ideal -3 dBFS)
localparam real AMP_TOL_DB = 1.5;

task check_thdn(input string mname, input integer cap_cnt, input integer ovf_cnt,
                input integer pk_pos, input integer pk_neg);
    integer pf;
    integer amp;
    real amp_dbfs;
begin
    pf = 1;
    amp = (pk_pos - pk_neg) / 2;
    if (amp > 0)
        amp_dbfs = 20.0 * $ln($itor(amp) / 32768.0) / $ln(10.0);
    else
        amp_dbfs = -99.0;

    if (cap_cnt != 4096) begin
        $display("  [FAIL] THD+N %s: captured %0d (exp 4096)", mname, cap_cnt);
        pf = 0;
    end
    if (ovf_cnt != 0) begin
        $display("  [FAIL] THD+N %s: %0d overflows", mname, ovf_cnt);
        pf = 0;
    end
    if (amp < 5000) begin
        $display("  [FAIL] THD+N %s: amplitude too low (%0d = %.1f dBFS)", mname, amp, amp_dbfs);
        pf = 0;
    end

    if (pf) begin
        $display("  [PASS] THD+N %s: %0d samples, ovf=%0d, amp=%0d (%.1f dBFS)",
                 mname, cap_cnt, ovf_cnt, amp, amp_dbfs);
        total_pass = total_pass + 1;
    end else begin
        total_fail = total_fail + 1;
    end
end
endtask

integer thdn_cap, thdn_ovf;
reg signed [15:0] thdn_pk_p, thdn_pk_n;

task run_thdn_checked(input [1:0] m, input string mname);
begin
    run_thdn(m, mname);
    thdn_cap = 0;
    thdn_ovf = overflow_count;
    thdn_pk_p = -16'sd32768;
    thdn_pk_n =  16'sd32767;
    begin : count_cap
        integer fc;
        integer val;
        fc = $fopen({"results/thdn_", mname, ".txt"}, "r");
        if (fc != 0) begin
            while ($fscanf(fc, "%d", val) == 1) begin
                thdn_cap = thdn_cap + 1;
                if ($signed(val[15:0]) > thdn_pk_p) thdn_pk_p = $signed(val[15:0]);
                if ($signed(val[15:0]) < thdn_pk_n) thdn_pk_n = $signed(val[15:0]);
            end
            $fclose(fc);
        end
    end
    check_thdn(mname, thdn_cap, thdn_ovf, thdn_pk_p, thdn_pk_n);
end
endtask

// =========================================================================
// #6  ITU-T P.50 Sending Distortion — Goertzel SDR
// =========================================================================
localparam integer GOERTZEL_N    = 1600;
localparam integer GOERTZEL_SKIP = 512;
localparam real    DBM0_REF      = 1449.0;
localparam real    SDR_THRESH_DB = 25.0;

real goertzel_buf [0:1599];
integer goertzel_cnt;

task collect_output_samples(
    input [1:0] m,
    input real freq,
    input real amp_dbm0,
    input integer n_skip,
    input integer n_cap
);
    integer adc_cnt, skip_done, cap_done;
    integer adc_amp;
    real lin;
begin
    configure_mode(m);
    do_reset();
    overflow_count = 0;

    lin = DBM0_REF * $pow(10.0, amp_dbm0 / 20.0);
    adc_amp = $rtoi(lin);
    if (adc_amp < 1) adc_amp = 1;

    skip_done = 0;
    cap_done  = 0;

    for (adc_cnt = 0; adc_cnt < MAX_ADC_PER_FREQ && cap_done < n_cap; adc_cnt = adc_cnt + 1) begin
        push_adc_sample(adc_amp, freq, adc_cnt);
        if (data_valid) begin
            if (skip_done < n_skip)
                skip_done = skip_done + 1;
            else begin
                goertzel_buf[cap_done] = $itor($signed(data_out));
                cap_done = cap_done + 1;
            end
        end
    end
    goertzel_cnt = cap_done;
end
endtask

task compute_sdr(
    input real freq,
    input real fs_out,
    output real sdr_db
);
    real w, coeff, s0, s1, s2;
    real fund_pwr, total_pwr;
    integer i;
begin
    w = PI2 * freq / fs_out;
    coeff = 2.0 * $cos(w);
    s1 = 0.0;
    s2 = 0.0;
    total_pwr = 0.0;

    for (i = 0; i < goertzel_cnt; i = i + 1) begin
        s0 = goertzel_buf[i] + coeff * s1 - s2;
        s2 = s1;
        s1 = s0;
        total_pwr = total_pwr + goertzel_buf[i] * goertzel_buf[i];
    end

    fund_pwr = 2.0 * (s1 * s1 + s2 * s2 - coeff * s1 * s2);
    total_pwr = total_pwr * $itor(goertzel_cnt);

    if (total_pwr > fund_pwr && fund_pwr > 0.0)
        sdr_db = 10.0 * $log10(fund_pwr / (total_pwr - fund_pwr));
    else if (fund_pwr > 0.0)
        sdr_db = 99.0;
    else
        sdr_db = -99.0;
end
endtask

task run_p50_distortion(input [1:0] m, input string mname, input real fs_out);
    integer fi, li;
    integer p50_freqs [0:7];
    integer num_p50_freqs;
    real    levels [0:5];
    integer num_levels;
    real    sdr;
    integer pf, sf_p50;
begin
    case (m)
        MODE_NB: begin
            num_p50_freqs = 5;
            p50_freqs[0] = 315; p50_freqs[1] = 408; p50_freqs[2] = 510;
            p50_freqs[3] = 816; p50_freqs[4] = 1020;
        end
        MODE_WB: begin
            num_p50_freqs = 8;
            p50_freqs[0] = 200; p50_freqs[1] = 315; p50_freqs[2] = 408;
            p50_freqs[3] = 510; p50_freqs[4] = 816; p50_freqs[5] = 1020;
            p50_freqs[6] = 1600; p50_freqs[7] = 2000;
        end
        default: begin
            num_p50_freqs = 8;
            p50_freqs[0] = 200; p50_freqs[1] = 500; p50_freqs[2] = 1020;
            p50_freqs[3] = 2000; p50_freqs[4] = 4000; p50_freqs[5] = 6000;
            p50_freqs[6] = 7000; p50_freqs[7] = 8000;
        end
    endcase

    num_levels = 6;
    levels[0] = -6.0; levels[1] = -10.0; levels[2] = -16.0;
    levels[3] = -20.0; levels[4] = -25.0; levels[5] = -31.0;

    sf_p50 = $fopen({"results/p50_", mname, ".txt"}, "w");
    $fwrite(sf_p50, "test,freq_hz,level_dbm0,sdr_db,overflow,pass\n");

    pf = 1;

    $display("    Freq sweep @ -16 dBm0:");
    for (fi = 0; fi < num_p50_freqs; fi = fi + 1) begin
        collect_output_samples(m, $itor(p50_freqs[fi]), -16.0, GOERTZEL_SKIP, GOERTZEL_N);
        compute_sdr($itor(p50_freqs[fi]), fs_out, sdr);
        begin : fs_check
            integer ok;
            ok = (sdr >= SDR_THRESH_DB && overflow_count == 0) ? 1 : 0;
            if (!ok) pf = 0;
            $display("      %0d Hz: SDR=%.1f dB  ovf=%0d  %s",
                     p50_freqs[fi], sdr, overflow_count, ok ? "PASS" : "FAIL");
            $fwrite(sf_p50, "freq,%0d,-16,%.1f,%0d,%0d\n",
                    p50_freqs[fi], sdr, overflow_count, ok);
        end
    end

    $display("    Level sweep @ 1020 Hz:");
    for (li = 0; li < num_levels; li = li + 1) begin
        collect_output_samples(m, 1020.0, levels[li], GOERTZEL_SKIP, GOERTZEL_N);
        compute_sdr(1020.0, fs_out, sdr);
        begin : ls_check
            integer ok;
            ok = (sdr >= SDR_THRESH_DB && overflow_count == 0) ? 1 : 0;
            if (!ok) pf = 0;
            $display("      %.0f dBm0: SDR=%.1f dB  ovf=%0d  %s",
                     levels[li], sdr, overflow_count, ok ? "PASS" : "FAIL");
            $fwrite(sf_p50, "level,1020,%.0f,%.1f,%0d,%0d\n",
                    levels[li], sdr, overflow_count, ok);
        end
    end

    $fclose(sf_p50);

    if (pf) begin
        $display("  [PASS] P.50 %s", mname);
        total_pass = total_pass + 1;
    end else begin
        $display("  [FAIL] P.50 %s", mname);
        total_fail = total_fail + 1;
    end
end
endtask

// =========================================================================
// #7  Square-wave stress test
// =========================================================================
task push_adc_square(input integer amplitude, input real freq, input integer idx);
begin
    @(negedge clk);
    begin : gen_sq
        real phase;
        integer q;
        phase = freq * $itor(idx) / FS_ADC;
        phase = phase - $floor(phase);
        q = (phase < 0.5) ? amplitude : -amplitude;
        if (q >  2047) q =  2047;
        if (q < -2048) q = -2048;
        adc_data = q[11:0];
    end
    eoc = 1'b1;
    @(negedge clk);
    eoc = 1'b0;
    @(posedge clk);
end
endtask

task run_squarewave_stress(input [1:0] m, input string mname);
    integer adc_cnt, out_cnt, skip_cnt;
    integer sq_freqs [0:2];
    integer nf, fi;
    integer pf;
    integer sq_fd;
    string sq_fname;
begin
    sq_freqs[0] = 100; sq_freqs[1] = 1000; sq_freqs[2] = 2000;
    nf = 3;
    pf = 1;

    sq_fname = {"results/sqwave_", mname, ".txt"};
    sq_fd = $fopen(sq_fname, "w");
    $fwrite(sq_fd, "freq_hz,sample_idx,value\n");

    for (fi = 0; fi < nf; fi = fi + 1) begin
        configure_mode_headroom(m);
        do_reset();
        overflow_count = 0;
        skip_cnt = 0;
        out_cnt  = 0;

        for (adc_cnt = 0; adc_cnt < 500000 && out_cnt < 512; adc_cnt = adc_cnt + 1) begin
            push_adc_square(2047, $itor(sq_freqs[fi]), adc_cnt);
            if (data_valid) begin
                if (skip_cnt < 256)
                    skip_cnt = skip_cnt + 1;
                else begin
                    $fwrite(sq_fd, "%0d,%0d,%0d\n", sq_freqs[fi], out_cnt, $signed(data_out));
                    out_cnt = out_cnt + 1;
                end
            end
        end

        begin : sq_check
            integer ok;
            ok = (overflow_count == 0 && out_cnt >= 512) ? 1 : 0;
            if (!ok) pf = 0;
            $display("    %s sqwave %0d Hz: out=%0d ovf=%0d %s",
                     mname, sq_freqs[fi], out_cnt, overflow_count, ok ? "PASS" : "FAIL");
        end
    end

    $fclose(sq_fd);

    if (pf) begin
        $display("  [PASS] Squarewave %s", mname);
        total_pass = total_pass + 1;
    end else begin
        $display("  [FAIL] Squarewave %s", mname);
        total_fail = total_fail + 1;
    end
end
endtask

// =========================================================================
// #8  Clean mode-switch test
// =========================================================================
task run_mode_switch_pair(
    input [1:0] m_a, input string name_a, input integer exp_rate_a,
    input [1:0] m_b, input string name_b, input integer exp_rate_b,
    output integer pass
);
    integer adc_cnt, out_cnt;
    integer rate_a, rate_b;
begin
    pass = 1;

    configure_mode(m_a);
    do_reset();
    overflow_count = 0;
    out_cnt = 0;
    for (adc_cnt = 0; adc_cnt < 200000; adc_cnt = adc_cnt + 1) begin
        push_adc_sample(AMP_M3DBFS, 1000.0, adc_cnt);
        if (data_valid) out_cnt = out_cnt + 1;
    end
    rate_a = out_cnt;
    if (overflow_count != 0) pass = 0;

    configure_mode(m_b);
    do_reset();
    overflow_count = 0;
    out_cnt = 0;
    for (adc_cnt = 0; adc_cnt < 200000; adc_cnt = adc_cnt + 1) begin
        push_adc_sample(AMP_M3DBFS, 1000.0, adc_cnt);
        if (data_valid) out_cnt = out_cnt + 1;
    end
    rate_b = out_cnt;
    if (overflow_count != 0) pass = 0;

    begin : rate_check
        integer exp_a, exp_b;
        exp_a = 200000 / (3072000 / exp_rate_a);
        exp_b = 200000 / (3072000 / exp_rate_b);
        if (rate_a < exp_a - 2 || rate_a > exp_a + 2) pass = 0;
        if (rate_b < exp_b - 2 || rate_b > exp_b + 2) pass = 0;
        $display("    %s->%s: rateA=%0d(exp%0d) rateB=%0d(exp%0d) ovf=%0d %s",
                 name_a, name_b, rate_a, exp_a, rate_b, exp_b,
                 overflow_count, pass ? "PASS" : "FAIL");
    end
end
endtask

task run_mode_switch_test;
    integer p1, p2, p3;
begin
    run_mode_switch_pair(MODE_NB, "nb", 8000, MODE_WB, "wb", 16000, p1);
    run_mode_switch_pair(MODE_WB, "wb", 16000, MODE_SWB, "swb", 32000, p2);
    run_mode_switch_pair(MODE_SWB, "swb", 32000, MODE_NB, "nb", 8000, p3);

    if (p1 && p2 && p3) begin
        $display("  [PASS] Mode switch");
        total_pass = total_pass + 1;
    end else begin
        $display("  [FAIL] Mode switch");
        total_fail = total_fail + 1;
    end
end
endtask

// =========================================================================
// #10  Full-scale 0 dBFS test (no saturation)
// =========================================================================
task run_fullscale_test(input [1:0] m, input string mname);
    integer adc_cnt, out_cnt, skip_cnt;
    reg signed [15:0] pk_pos, pk_neg;
    integer pf;
begin
    configure_mode_headroom(m);
    do_reset();
    overflow_count = 0;
    skip_cnt = 0;
    out_cnt  = 0;
    pk_pos = -16'sd32768;
    pk_neg =  16'sd32767;

    for (adc_cnt = 0; adc_cnt < 2000000 && out_cnt < 1024; adc_cnt = adc_cnt + 1) begin
        push_adc_sample(2047, 1000.0, adc_cnt);
        if (data_valid) begin
            if (skip_cnt < 512)
                skip_cnt = skip_cnt + 1;
            else begin
                if ($signed(data_out) > pk_pos) pk_pos = $signed(data_out);
                if ($signed(data_out) < pk_neg) pk_neg = $signed(data_out);
                out_cnt = out_cnt + 1;
            end
        end
    end

    pf = (overflow_count == 0 && out_cnt >= 1024 && pk_pos < 16'sd32767 && pk_neg > -16'sd32768) ? 1 : 0;
    $display("    %s 0dBFS: pk+=%0d pk-=%0d out=%0d ovf=%0d %s",
             mname, pk_pos, pk_neg, out_cnt, overflow_count, pf ? "PASS" : "FAIL");

    if (pf) begin
        total_pass = total_pass + 1;
    end else begin
        total_fail = total_fail + 1;
    end
end
endtask

// =========================================================================
// Main test sequence
// =========================================================================
initial begin
    total_pass = 0;
    total_fail = 0;

    $display("=== THD+N Tests: 1kHz @ -3dBFS ===");
    run_thdn_checked(MODE_SWB, "swb");
    run_thdn_checked(MODE_WB,  "wb");
    run_thdn_checked(MODE_NB,  "nb");

    $display("=== Frequency Response Sweeps @ -3dBFS ===");
    $display("  NB sweep...");
    run_freq_sweep(MODE_NB, "nb");
    $display("  WB sweep...");
    run_freq_sweep(MODE_WB, "wb");
    $display("  SWB sweep...");
    run_freq_sweep(MODE_SWB, "swb");

    $display("=== ITU-T P.50 Distortion (SDR via Goertzel) ===");
    $display("  NB P.50...");
    run_p50_distortion(MODE_NB, "nb", 8000.0);
    $display("  WB P.50...");
    run_p50_distortion(MODE_WB, "wb", 16000.0);
    $display("  SWB P.50...");
    run_p50_distortion(MODE_SWB, "swb", 32000.0);

    $display("=== Square-wave Stress Test ===");
    run_squarewave_stress(MODE_NB, "nb");
    run_squarewave_stress(MODE_WB, "wb");
    run_squarewave_stress(MODE_SWB, "swb");

    $display("=== Mode Switch Test ===");
    run_mode_switch_test();

    $display("=== Full-scale 0 dBFS Test ===");
    run_fullscale_test(MODE_NB, "nb");
    run_fullscale_test(MODE_WB, "wb");
    run_fullscale_test(MODE_SWB, "swb");

    $display("");
    $display("============================================");
    $display("  SUMMARY: %0d PASS, %0d FAIL (of %0d tests)",
             total_pass, total_fail, total_pass + total_fail);
    if (total_fail == 0)
        $display("  STATUS: ALL TESTS PASSED");
    else
        $display("  STATUS: %0d TEST(S) FAILED", total_fail);
    $display("  Overflows total: checked per-test");
    $display("============================================");
    $finish;
end

endmodule
