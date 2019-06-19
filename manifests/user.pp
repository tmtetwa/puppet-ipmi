 # == Defined resource type: ipmi::user
#

define ipmi::user (
  $password,
  $user = 'root',
  $priv = 4,
  $prive = 1,
  $user_id = 3,
  $ensure = present,
)
{
  require ::ipmi

  validate_string($password,$user)
  validate_integer($priv)
  validate_integer($prive)
  validate_integer($user_id)
  validate_string($ensure, '^present$|^absent')

  case $priv {
    1: {$privilege = 'CALLBACK'}
    2: {$privilege = 'USER'}
    3: {$privilege = 'OPERATOR'}
    4: {$privilege = 'ADMINISTRATOR'}
    default: {fail('invalid privilege level specified')}
  }


  if ($ensure == present)
    {
      exec { "ipmi_user_enable_${title}":
        command     => "/usr/bin/ipmitool user enable ${user_id}",
        refreshonly => true,
        }

      exec { "ipmi_user_add_${title}":
        command => "/usr/bin/ipmitool user set name ${user_id} ${user}",
        unless  => "/usr/bin/test \"$(ipmitool user list 1 | grep '^${user_id}' | awk '{print \$2}')\" = \"${user}\"",
        notify  => [Exec["ipmi_user_priv_${title}"], Exec["ipmi_user_setpw_${title}"]],
        }

      exec { "ipmi_user_priv_${title}":
        command => "/usr/bin/ipmitool user priv ${user_id} ${priv} 1",
        unless  => "/usr/bin/test \"$(ipmitool user list 1 | grep '^${user_id}' | awk '{print \$6}')\" = ${privilege}",
        notify  => [Exec["ipmi_user_enable_${title}"], Exec["ipmi_user_enable_sol_${title}"], Exec["ipmi_user_channel_setaccess_${title}"]],
        }

      exec { "ipmi_user_setpw_${title}":
        command => "/usr/bin/ipmitool user set password ${user_id} \'${password}\'",
        unless  => "/usr/bin/ipmitool user test ${user_id} 16 \'${password}\'",
        notify  => [Exec["ipmi_user_enable_${title}"], Exec["ipmi_user_enable_sol_${title}"], Exec["ipmi_user_channel_setaccess_${title}"]],
        }

      exec { "ipmi_user_enable_sol_${title}":
        command     => "/usr/bin/ipmitool sol payload enable 1 ${user_id}",
        refreshonly => true,
        }

      exec { "ipmi_user_channel_setaccess_${title}":
        command     => "/usr/bin/ipmitool channel setaccess 1 ${user_id} callin=on ipmi=on link=on privilege=${priv}",
        refreshonly => true,
        }
      }
    elsif ( $ensure == absent)
    {
      exec { "ipmi_user_enable_nouser":
        command     => "/usr/bin/ipmitool user enable ${user_id}",
        refreshonly => false,
        }

      exec { "ipmi_user_add_username-nouser":
        command => "/usr/bin/ipmitool user set name ${user_id} nouser",
        unless  => "/usr/bin/test \"$(ipmitool user list 1 | grep '^${user_id}' | awk '{print \$2}')\" = \"nouser\"",
        notify  => [Exec["ipmi_user_priv_nouser"], Exec["ipmi_user_setpw_nopw"]],
        }

      exec { "ipmi_user_setpw_nopw":
        command => "/usr/bin/ipmitool user set password ${user_id} \''",
        unless  => "/usr/bin/ipmitool user test ${user_id} 16 \''",
        notify  => [Exec["ipmi_user_enable_nouser"], Exec["ipmi_user_enable_sol_nouser"], Exec["ipmi_user_channel_setaccess_nouser"]],
        }

        exec { "ipmi_user_priv_nouser":
          command => "/usr/bin/ipmitool user priv ${user_id} $priv 1",
          unless  => "/usr/bin/test \"$(ipmitool user list 1 | grep '^${user_id}' | awk '{print \$6}')\" = ${privilege}",
          notify  => [Exec["ipmi_user_enable_nouser"], Exec["ipmi_user_enable_sol_nouser"], Exec["ipmi_user_channel_setaccess_nouser"]],
          }

        exec { "ipmi_user_enable_sol_nouser":
          command     => "/usr/bin/ipmitool sol payload enable 1 ${user_id}",
          refreshonly => false,
          }

        exec { "ipmi_user_channel_setaccess_nouser":
          command     => "/usr/bin/ipmitool channel setaccess 1 ${user_id} callin=off ipmi=on link=off privilege=$prive",
          refreshonly => false,
        }
      }
    else
      {
        notify { "Error occured, not allowed execution": }
      }
  }
