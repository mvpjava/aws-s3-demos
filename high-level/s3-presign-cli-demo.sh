#!/bin/sh

aws s3 presign 's3://aws-developer-resources-triomni/Developing on AWS V4.0 Course Agenda.pdf'  --expires-in 600

