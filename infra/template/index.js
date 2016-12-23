const config = require("config");
const fs = require("fs");
const Util = require("cloudformation-z").Util;

const DomainName = "xmas.kinoboku.net";

module.exports = {
    "AWSTemplateFormatVersion": "2010-09-09",
    "Description": "Merry Xmas!",

    "Resources": {
        "DocumentS3": {
            "Type": "AWS::S3::Bucket",
            "Properties": {
                "BucketName": DomainName,
                "WebsiteConfiguration": {
                    "IndexDocument": "index.html"
                }
            }
        },
        "DocsDNS": {
            "Type": "AWS::Route53::RecordSet",
            "Properties": {
                "Type": "A",
                "Name": `${DomainName}.`,
                "HostedZoneName": `${DomainName}.`,
                "AliasTarget": {
                    "DNSName": "s3-website-ap-northeast-1.amazonaws.com.",
                    "HostedZoneId": "Z2M4EHUR26P7ZW"
                }
            }
        }
    },
    "Outputs": {
        "DocumentS3": { "Value": { "Ref": "DocumentS3" } }
    }
}

