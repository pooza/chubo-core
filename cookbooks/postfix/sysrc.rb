exit unless node.platform == 'freebsd'

execute 'sysrc sendmail_enable="NONE"'
execute 'sysrc sendmail_submit_enable="NO"'
execute 'sysrc sendmail_outbound_enable="NO"'
execute 'sysrc sendmail_msp_queue_enable="NO"'
execute 'sysrc postfix_enable="YES"'
