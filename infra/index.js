"use strict";

var CFNZ = require("cloudformation-z");
var config = require("config");
var template = require("./template/index.js");

var commander = new CFNZ.EasyCommander(config, template);
commander.exec(process.argv);
