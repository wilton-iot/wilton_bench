/*
 * Copyright 2018, alex at staticlibs.net
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

define([
    "module",
    "lodash/forEach",
    "wilton/fs",
    "wilton/Logger",
    "wilton/net",
    "wilton/process",
    "wilton/utils"
], function(module, forEach, fs, Logger, net, process, utils) {
    "use strict";

    var logger = new Logger(module.id);

    function startServer(sconf, serverPort) {
        logger.info("Starting server, sample: [" + sconf.name + "] ...");
        var output = sconf.name + "/server_out.txt";
        var pid = process.spawn({
            executable: sconf.executable,
            args: sconf.args,
            outputFile: output,
            awaitExit: false
        });
        net.waitForTcpConnection({
            ipAddress: "127.0.0.1",
            tcpPort: serverPort,
            timeoutMillis: 1000
        });
        logger.info("Server started, pid: [" + pid + "]");
        return pid;
    }

    function stopServer(sconf, pid) {
        logger.info("Stopping server, sample: [" + sconf.name + "], pid: [" + pid + "] ...");
        var output = sconf.name + "/server_stop_out.txt";
        var code = process.spawn({
            executable: "/bin/kill",
            args: [String(pid)],
            outputFile: output,
            awaitExit: true
        });
        if (0 !== code) throw new Error("Error stopping server," +
                " sample: [" + sconf.name + "]" +
                " exit code: [" + code + "]" +
                " output path: [" + output + "]");
        logger.info("Server stopped");
    }

    function startNmon(nconf, sampleName) {
        logger.info("Starting nmon, sample: [" + sampleName + "] ...");
        var outputPid = sampleName + "/nmon_pid_out.txt";
        var outputNmon = sampleName + "/" + sampleName + ".nmon";
        var args = ["-F", outputNmon];
        forEach(nconf.args, function(ar) {
            args.push(ar);
        });
        var code = process.spawn({
            executable: nconf.executable,
            args: args,
            outputFile: outputPid,
            awaitExit: true
        });
        if (0 !== code) throw new Error("Error starting nmon," +
                " sample: [" + sampleName + "]" +
                " exit code: [" + code + "]" +
                " output path: [" + outputPid + "]");
        var pidStr = fs.readFile(outputPid);
        var pid = parseInt(pidStr, 10);
        if (!(pid > 0)) throw new Error("Error obtaining nmon pid," +
                " sample: [" + sampleName + "]" +
                " pid string: [" + pidStr + "]" +
                " output path: [" + outputPid + "]");
        logger.info("Nmon started, pid: [" + pid + "]");
        return pid;
    }

    function stopNmon(sampleName, pid) {
        logger.info("Stopping nmon, sample: [" + sampleName + "], pid: [" + pid + "] ...");
        var output = sampleName + "/nmon_stop_out.txt";
        var code = process.spawn({
            executable: "/bin/kill",
            args: [String(pid)],
            outputFile: output,
            awaitExit: true
        });
        if (0 !== code) throw new Error("Error stopping nmon," +
                " sample: [" + sampleName + "]" +
                " exit code: [" + code + "]" +
                " output path: [" + output + "]");
        logger.info("Nmon stopped");
    }

    function runWrkWarmup(wconf, sampleName) {
        logger.info("Running wrk warmup, sample: [" + sampleName + "] ...");
        var outputWarm = sampleName + "/wrk_warmup_out.txt";
        var code = process.spawn({
            executable: wconf.executable,
            args: wconf.argsWarmup,
            outputFile: outputWarm,
            awaitExit: true
        });
        if (0 !== code) throw new Error("Error running wrk warmup," +
                " sample: [" + sampleName + "]" +
                " exit code: [" + code + "]" +
                " output path: [" + outputWarm + "]");
        logger.info("Wrk warmup finishes");
    }

    function runWrk(wconf, sampleName) {
        logger.info("Running wrk, sample: [" + sampleName + "] ...");
        var output = sampleName + "/wrk_out.txt";
        var code = process.spawn({
            executable: wconf.executable,
            args: wconf.args,
            outputFile: output,
            awaitExit: true
        });
        if (0 !== code) throw new Error("Error running wrk," +
                " sample: [" + sampleName + "]" +
                " exit code: [" + code + "]" +
                " output path: [" + output + "]");
        var outText = fs.readFile(output);
        logger.info("Wrk finishes:\n" + outText);
    }

    function runSample(conf, sa) {
        if (fs.exists(sa.name)) {
            fs.rmdir(sa.name);
        }
        fs.mkdir(sa.name);
        var npid = 0;
        var spid = 0;
        try {
            spid = startServer(sa, conf.serverPort);
            runWrkWarmup(conf.wrk, sa.name);
            npid = startNmon(conf.nmon, sa.name);
            runWrk(conf.wrk, sa.name);
        } finally {
            if (0 !== spid) {
                stopNmon(sa.name, npid);
                stopServer(sa, spid);
            }
        }
    }

    return {
        main: function(confpath) {
            Logger.initConsole("INFO");
            var conf = JSON.parse(fs.readFile(confpath));
            forEach(conf.samples, function(sa) {
                if (sa.enabled) {
                    runSample(conf, sa);
                }
            });
            logger.info("Benchmarks finished successfully");
        }
    };

});
