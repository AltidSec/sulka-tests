"""Keywords that modify content in a built image.

The tests modify images to check that a modification is detected.
"""

import mmap


def invert_byte_in_content(image, content_file, length=None):
    """Invert the bits of the byte in the middle of the content of
    ``content_file`` in ``image``, so that it changes whatever its value is.

    Only the first ``length`` bytes of ``content_file`` are looked for when
    ``length`` is given. Fail unless the content is found exactly once, as the
    location would otherwise be ambiguous.
    """
    with open(content_file, 'rb') as f:
        content = f.read(int(length)) if length is not None else f.read()
    if not content:
        raise AssertionError('%s is empty' % content_file)
    with open(image, 'r+b') as f, mmap.mmap(f.fileno(), 0) as data:
        offset = data.find(content)
        if offset == -1 or data.find(content, offset + 1) != -1:
            raise AssertionError('Expected the content of %s once in %s' % (content_file, image))
        data[offset + len(content) // 2] ^= 0xff
