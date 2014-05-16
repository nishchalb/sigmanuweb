#!/usr/bin/env ruby

time_string = Time.now.strftime("%Y-%m-%d %Hh%Mm")
BACKUP_DIR = "/media/snstorage/Webhamster/backups"
SOURCE_DIR = "/home/hamster/"

%x[tar -C #{SOURCE_DIR} -zcf "#{BACKUP_DIR}/backup-#{time_string}.tar.gz" .]

