# loads all unit tests in the test directory

(set tests ((NSString stringWithShellCommand:"ls test/test_*.nu") lines))

(tests each:
  (do (test)
    (load test)))
