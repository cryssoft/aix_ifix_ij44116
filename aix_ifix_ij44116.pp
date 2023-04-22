#
#  2023/02/27 - cp - Added the new check based on aix_ifix_package.
#
#-------------------------------------------------------------------------------
#
#  From Advisory.asc:
#
#-------------------------------------------------------------------------------
#
class aix_ifix_ij44116 {

    #  Make sure we can get to the ::staging module (deprecated ?)
    include ::staging

    #  This only applies to AIX and maybe VIOS in later versions
    if ($::facts['osfamily'] == 'AIX') {

        #  Set the ifix ID up here to be used later in various names
        $ifixName = 'IJ44116'

        #  Make sure we create/manage the ifix staging directory
        require aix_file_opt_ifixes

        #
        #  For now, we're skipping anything that reads as a VIO server.
        #  We have no matching versions of this ifix / VIOS level installed.
        #
        unless ($::facts['aix_vios']['is_vios']) {

            #  2023/02/27 - cp - Added this check to keep this ifix safe
            if ('bos.pfcdd.rte' in $::facts['aix_ifix_package'].keys) {
                #
                #  Friggin' IBM...  The ifix ID that we find and capture in the fact has the
                #  suffix allready applied.
                #
                if ($::facts['kernelrelease'] == '7200-05-02-2114') {
                    $ifixSuffix = 's2a'
                    $ifixBuildDate = '221102'
                }
                else {
                    $ifixSuffix = 'unknown'
                    $ifixBuildDate = 'unknown'
                }
            }
            else {
                $ifixSuffix = 'unknown'
                $ifixBuildDate = 'unknown'
            }

            #  Add the name and suffix to make something we can find in the fact
            $ifixFullName = "${ifixName}${ifixSuffix}"

            #  If we set our $ifixSuffix and $ifixBuildDate, we'll continue
            if (($ifixSuffix != 'unknown') and ($ifixBuildDate != 'unknown')) {

                #  Don't bother with this if it's already showing up installed
                unless ($ifixFullName in $::facts['aix_ifix']['hash'].keys) {
 
                    #  Build up the complete name of the ifix staging source and target
                    $ifixStagingSource = "puppet:///modules/aix_ifix_ij44116/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"
                    $ifixStagingTarget = "/opt/ifixes/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"

                    #  Stage it
                    staging::file { "$ifixStagingSource" :
                        source  => "$ifixStagingSource",
                        target  => "$ifixStagingTarget",
                        before  => Exec["emgr-install-${ifixName}"],
                    }

                    #  GAG!  Use an exec resource to install it, since we have no other option yet
                    exec { "emgr-install-${ifixName}":
                        path     => '/bin:/sbin:/usr/bin:/usr/sbin:/etc',
                        command  => "/usr/sbin/emgr -e $ifixStagingTarget",
                        unless   => "/usr/sbin/emgr -l -L $ifixFullName",
                    }

                    #  Explicitly define the dependency relationships between our resources
                    File['/opt/ifixes']->Staging::File["$ifixStagingSource"]->Exec["emgr-install-${ifixName}"]

                }

            }

        }

    }

}
