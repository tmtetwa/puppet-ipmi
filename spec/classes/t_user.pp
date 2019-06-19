
class ::ipmii
{

describe 'ipmi class' do
	
if ( $ensure == absent )
       {
        ipmi::user { 'no-useer-created':
        user     => 'no-useer-created',
        password => '',
                }
        }
