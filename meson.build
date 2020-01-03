project('opentmpfiles', 'c',
  version : '0.2',
  license: 'BSD-2',
  default_options : [
    'c_std=c99',
	'prefix=/usr',
    'warning_level=3',
    ],
  meson_version : '>=0.52.1')

install_data('tmpfiles.sh',
	install_dir : get_option('bindir'),
		install_mode : 'rwxr-xr-x',
	rename : 'tmpfiles')
