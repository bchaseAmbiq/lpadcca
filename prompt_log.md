# Prompt Log

## Prompt 1 — 2026-04-10

I need to continue this project. Can you track all my prompts in a file word for word? What is the status of DV with this RTL? Does the RTL match the C-code bit-for-bit exact? Does a SW driver exist? This IP needs to connect to a APB port which is in an M55 subsystem. I need the HAL code, SW driver, HTML documentation and small M55 application. I also need an FPGA image created which has the underlying RTL and also some test structures around it (e.g. canned data). These test structures should exercise the RTL so we can confirm the behavior on an FPGA board (Stratix S10). Give me a short summary of the status of all this, then make a plan to get through it. I will need to give you an example HTML document. Can I put this into some git issue? How best to get that to you? Create git issues for all this.

## Prompt 2 — 2026-04-10

Do 17, 12, 13, 14, 15

Do 17, 12, 13, 15

## Prompt 3 — 2026-04-10

For 14, use the html file I put in the issue directory

## Prompt 4 — 2026-04-10

What other open issues exist?

## Prompt 5 — 2026-04-10

Are there plots for 6 and 7? Make sure there are plots.

## Prompt 6 — 2026-04-10

What's the blocker for 9? When you give a status table update, can you wrap the text in the table? I cannot use the slider bar across the bottom.

## Prompt 7 — 2026-04-10

Add a FIFO to the output. Do you already have the necessary details in an issue? It needs to connect to APB with half-full, full, empty, depth 16. the flags should trigger interrupts (to an M55 CPU) and be readable, clearable and enabled/disabled independntly. If there is no issue describing this, add one, or merge this with the open issue.

## Prompt 8 — 2026-04-10

What open issues exist?

## Prompt 9 — 2026-04-10

Do I have a zipfile which has scripts to run sim and syn?

## Prompt 10 — 2026-04-10

Yes, create a new zipfile which has scripts for me to run all sim test benches, create plots, run syn and analyzer power consumption.

## Prompt 11 — 2026-04-23

how to unzip it?

## Prompt 12 — 2026-04-23

Does one syn script do both the core and APB or do I need to run both? I want only 1 syn script.

## Prompt 13 — 2026-04-23

I need the total power consumption over all blocks including as samples go into the fifo. Will it do that?

## Prompt 14 — 2026-04-23

Let me bring you the sim results first. Why is the results sim file > 2MB?

## Prompt 15 — 2026-04-23

I put the sim results into sim_results_02423_1809 and unzipped the file. Evaluate it.

## Prompt 16 — 2026-04-23

For the png files, put them into one PDF or HTML file so I can easily page through and look at them. To each image, add subtle text showing the date and time in Pacific TZ that the plot was created. Also the WB Frequency Response fails at 2 points, <150 Hz. Can you fix this? Also the square wave plots don't look right, do you think they are right?

## Prompt 17 — 2026-04-23

And can I also run syn with this? how to unzip?

## Prompt 18 — 2026-04-23

how to monitor both sim and syn jobs?

## Prompt 19 — 2026-04-23

make a directory for sim_results_0423_1834, unzip it and analyze it.

## Prompt 20 — 2026-04-23

What is the meaning of THD+N with result +/- 17293?

## Prompt 21 — 2026-04-23

Does the result in sqwave_nb.png look correct? Why does it not look like a square wave?

## Prompt 22 — 2026-04-23

For the SDR plots, are the results supposed to be above the red dotted line or below?

## Prompt 23 — 2026-04-23

Do the THD+N plots look good? Why are they single spikes, with some high and some very low?

## Prompt 24 — 2026-04-23

make a directory and unzip syn_results_0423_1832

## Prompt 25 — 2026-04-23

Make me a zipefil of this project which I can unzip elsewhere and have another LLM push it to a new github repo. Include all source code, inputs, outputs, prompts, issues... everything.
