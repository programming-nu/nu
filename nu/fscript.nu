;; @file fscript.nu
;; @discussion Nu helpers for working with F-Script.
;;
;; @copyright Copyright (c) 2007 Tim Burks, Radtastical Inc.
;;
;;   Licensed under the Apache License, Version 2.0 (the "License");
;;   you may not use this file except in compliance with the License.
;;   You may obtain a copy of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS,
;;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;   See the License for the specific language governing permissions and
;;   limitations under the License.

(load "FScript")

(function fs-browse (object)
     (set browser (BigBrowser
                             bigBrowserWithRootObject:object
                             interpreter:(FSInterpreter interpreter)))
     (browser makeKeyAndOrderFront:0)
     (unless $fs-browsers (set $fs-browsers (array)))
     ($fs-browsers << browser)
     browser)

