import unittest
from generate_content import validate_ui, validate_words, LANGUAGES


class ContentValidationTests(unittest.TestCase):
    def test_missing_word_translation_is_rejected(self):
        row = {'id': 'one', 'category': 'Food', 'difficulty': 1,
               **{code: 'Pizza' for code in LANGUAGES}}
        del row['ja']
        with self.assertRaisesRegex(ValueError, 'Invalid ja'):
            validate_words([row])

    def test_duplicate_localized_concept_is_rejected(self):
        first = {'id': 'one', 'category': 'Food', 'difficulty': 1,
                 **{code: 'Pizza' for code in LANGUAGES}}
        second = {'id': 'two', 'category': 'Food', 'difficulty': 1,
                  **{code: 'Bread' for code in LANGUAGES}, 'ja': 'Pizza'}
        with self.assertRaisesRegex(ValueError, 'Duplicate ja'):
            validate_words([first, second])

    def test_missing_ui_keys_and_changed_placeholders_are_rejected(self):
        source = 'Pass to {name}'
        good = {code: {source: 'Example {name}'} for code in LANGUAGES[2:]}
        validate_ui(good, {source})
        good['fr'][source] = 'Example {number}'
        with self.assertRaisesRegex(ValueError, 'Placeholder mismatch'):
            validate_ui(good, {source})
        good['fr'] = {}
        with self.assertRaisesRegex(ValueError, 'Incomplete UI catalog'):
            validate_ui(good, {source})


if __name__ == '__main__':
    unittest.main()
