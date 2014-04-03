# vim:fileencoding=utf-8

from __future__ import unicode_literals, absolute_import

import os
import re

from powerline.lib.unicode import u
from powerline.theme import requires_segment_info


@requires_segment_info
def full_path(pl, segment_info, dir_limit_depth=None, dir_root_length=3, ellipsis=" … "):
    """Returns a segment containing the full path of the current working
    directory."""
    try:
        cwd = u(segment_info['getcwd']())
    except OSError as e:
        if e.errno == 2:
            # user most probably deleted the directory
            # this happens when removing files from Mercurial repos for example
            pl.warn('Current directory not found')
            cwd = "[not found]"
        else:
            raise
    home = segment_info['home']
    if home:
        home = u(home)
        cwd = re.sub('^' + re.escape(home), '~', cwd, 1)

    # Split and cut out the current directory
    cwd_split = cwd.split(os.sep)[:-1]

    # Limit depth but include a bit of the beginning of the path
    if dir_limit_depth and len(cwd_split) > dir_limit_depth:

        if dir_root_length <= dir_limit_depth/2:
            dir_limit_depth -= dir_root_length
        else:
            dir_root_length = dir_limit_depth/2
            dir_limit_depth /= 2

        first = cwd_split[:dir_root_length]
        second = cwd_split[-dir_limit_depth:]
        cwd_split = first + [ellipsis] + second

    return os.sep.join(cwd_split)
