# RailsLogDeinterleaver

Rails logs in production are usually written to by multiple processes. This causes the log entries for a single request to be interleaved with other requests making the logs hard to read.

This gem includes a command line script to parse the interleaved logs and output logs grouped by the request, using the pid of the server process. it acts like the tail command, and monitors a continually updating log file.

Note that I am using syslog/rails 3 so the logs will be in a slightly different format that what rails will output by default in Rails 4. But this library could be easily updated to support both.


Install
-------
gem install rails_log_deinterleaver

Use
---
rails_log_deinterleaver [options] /path/to/interleaved/railslog.log
### possible options
-o, --output=x : Where to write the formatted log (if not specified stdout will be used)
-b, --backward=x : Start from the bottom of the file, x lines from the end. If not specified, the whole file will be parsed.
