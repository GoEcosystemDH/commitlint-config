module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat', 'fix', 'refactor', 'docs', 'test',
        'chore', 'perf', 'ci', 'build', 'style', 'revert'
      ]
    ],
    'subject-empty': [2, 'never'],
    'type-empty': [2, 'never'],
    'subject-max-length': [2, 'always', 100]
  }
};
