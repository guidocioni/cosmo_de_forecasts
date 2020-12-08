# crontab settings
This document contains some info on how to set your cron jobs properly.

We use 0, 3, 6, 9, 12, 15, 18, 21 runs. The files for these runs are usually *all* ready on `opendata.dwd.de` at

- 01:40 GMT for 00Z run
- 05:30 GMT for 03Z run
- 08:30 GMT for 06Z run
- 11:30 GMT for 09Z run
- 13:50 GMT for 12Z run
- 16:05 GMT for 15Z run
- 20:35 GMT for 18Z run
- 22:45 GMT for 21Z run

Note that the 03Z run has more timesteps than the other (45 instead than 27 hours).
This means that we have to use different timing in `cron` as the timezone cannot be yet specified.
With DST (daylight saving time) between 28 March and 31 October usually, the difference is only one hour, so

- 02:40 CEST for 00Z run
- 06:30 CEST for 03Z run
- 09:30 CEST for 06Z run
- 12:30 CEST for 09Z run
- 14:50 CEST for 12Z run
- 17:05 CEST for 15Z run
- 21:35 CEST for 18Z run
- 23:45 CEST for 21Z run

Without DST we have to add another hour as the difference is of 2 hours in CET.

- 03:40 CEST for 00Z run
- 07:30 CEST for 03Z run
- 10:30 CEST for 06Z run
- 13:30 CEST for 09Z run
- 15:50 CEST for 12Z run
- 18:05 CEST for 15Z run
- 22:35 CEST for 18Z run
- 00:45 CEST for 21Z run (run of previous day!)

Here is an example of cron jobs configuration. We use the `SHELL` variable to make sure the job is started with `bash` and the `BASH_ENV` to load some of the binaries that we need in the job.

```bash
SHELL=/bin/bash
BASH_ENV=/home/user/.cron_jobs_default_load
# icon-eu forecasts
40    3      *     *     * /home/user/cosmo_de_forecasts/copy_data.run > /tmp/cosmo-d2/`date +\%Y\%m\%d\%H\%M\%S`-cron.log 2>&1
30    7      *     *     * /home/user/cosmo_de_forecasts/copy_data.run > /tmp/cosmo-d2/`date +\%Y\%m\%d\%H\%M\%S`-cron.log 2>&1
30    10      *     *     * /home/user/cosmo_de_forecasts/copy_data.run > /tmp/cosmo-d2/`date +\%Y\%m\%d\%H\%M\%S`-cron.log 2>&1
30    13     *     *     * /home/user/cosmo_de_forecasts/copy_data.run > /tmp/cosmo-d2/`date +\%Y\%m\%d\%H\%M\%S`-cron.log 2>&1
50    15     *     *     * /home/user/cosmo_de_forecasts/copy_data.run > /tmp/cosmo-d2/`date +\%Y\%m\%d\%H\%M\%S`-cron.log 2>&1
05    18     *     *     * /home/user/cosmo_de_forecasts/copy_data.run > /tmp/cosmo-d2/`date +\%Y\%m\%d\%H\%M\%S`-cron.log 2>&1
35    22     *     *     * /home/user/cosmo_de_forecasts/copy_data.run > /tmp/cosmo-d2/`date +\%Y\%m\%d\%H\%M\%S`-cron.log 2>&1
```
we save the output of the scripts always in the `/tmp/icon-eu/` folder with a name created using the current date.
The `.cron_jobs_default_load` looks like this on ubuntu
```bash
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/user/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/user/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/user/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/user/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# include all env vars that we need in our job
# export ....

```