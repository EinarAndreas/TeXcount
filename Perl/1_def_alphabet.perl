#:::: 
#::: Definitions related to word recognition and languages
#::

### Character classes to use as Unicode properties

# Character group representing digits 0-9 (more restrictive than Digits)
sub Is_digit { return <<END;
0030\t0039
END
}

# Character group representing letters (excluding logograms)
sub Is_alphabetic { return <<END;
+utf8::Alphabetic
-utf8::Ideographic
-utf8::Katakana
-utf8::Hiragana
-utf8::Thai
-utf8::Lao
-utf8::Hangul
END
}

# Character group representing letters (excluding logograms)
sub Is_alphanumeric { return <<END;
+utf8::Alphabetic
+utf8::Digit
-utf8::Ideographic
-utf8::Katakana
-utf8::Hiragana
-utf8::Thai
-utf8::Lao
-utf8::Hangul
END
}

# Character class for punctuation excluding special characters
sub Is_punctuation { return <<END;
+utf8::Punctuation
-0024\t0025
-005c
-007b\t007e
END
}

# Character group representing CJK characters
sub Is_cjk { return <<END;
+utf8::Han
+utf8::Katakana
+utf8::Hiragana
+utf8::Hangul
END
}

# Character group for CJK punctuation characters
sub Is_cjkpunctuation { return <<END;
3000\t303f
2018\t201f
ff01\tff0f
ff1a\tff1f
ff3b\tff3f
ff5b\tff65
END
}
