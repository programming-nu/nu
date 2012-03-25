;; @file       template.nu
;; @discussion Nu templating engine.
;;
;; @copyright  Copyright (c) 2007 Tim Burks, Radtastical Inc.
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

(class NSString
     ;; Get the last character of a string.
     (- (id) lastCharacter is
          (self substringFromIndex:(- (self length) 1))))

;; @class NuTemplate
;; @abstract Text templates for Nu.
;; @discussion Similar to Ruby's "embedded Ruby" (aka "erb"), this allows Nu expressions to be used
;; in templates to simplify programmatic generation of text in arbitrary formats.
;; Applications include generation of HTML, CSS, and Objective-C source code.
;; Like Ruby's "erb", expressions surrounded by &lt;%= and %&gt; are evaluated and replaced
;; by their string values and code surrounded by &lt;% and %&gt; is treated as embedded Nu code.

(class NuTemplate is NSObject
     
     ;; Read a template from a file and return a string to be parsed and evaluated to generate the desired text.
     (+ (id) scriptForFileNamed:(id) fileName is
          (set template (NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil))
          (self scriptForString:template))
     
     ;; Read a template from a file and return a code object to be evaluated to generate the desired text.
     (+ (id) codeForFileNamed:(id) fileName is
          (set template (NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil))
          (self codeForString:template))
     
     ;; Take a string corresponding to a template and generate code (parsed s-expressions) that can be evaluated
     ;; to generate the desired text.  The returned code should be evaluated in a context that defines all symbols
     ;; referenced in the template.
     (+ (id) codeForString: (id) template is
          ;; Parse the script into an internal s-expression representation.
          ;; The calling code should evaluate it with (eval code).
          (synchronized NuTemplate
               (set script (self scriptForString:template))
               (set parser ((NuParser alloc) init))
               (set code (parser parse:script))
               (if (parser incomplete) (NSException raise:"NuTemplateError" format:@"incomplete expression in template"))
               ;; temporary fix for retain cycle in parser. Parser owns context, context references parser.
               ((parser context) removeObjectForKey:'_parser)
               code))
     
     ;; Take a string corresponding to a template and generate a string that can be parsed and evaluated
     ;; to generate the desired text.  The returned string should be evaluated in a context that defines all symbols
     ;; referenced in the template.
     (+ (id) scriptForString: (id) template is
          (unless template
                  (NSLog "Warning: Nu template string is null, treating it as an empty string.")
                  (set template ""))
          
          ;; transform the template into a Nu program that generates the desired text
          (set text (NSMutableString stringWithString:template))
          
          (set seed (NuMath random))
          (set resultName "templateResult")
          (set tagName "EMBEDDED-#{seed}")
          
          ;; first, replace each embedded nu expression with code that
          ;; appends the value of the expression to the result
          (set p-expression /<%= (.*?) %>/)
          (while (set match (p-expression findInString:text))
                 (text replaceCharactersInRange:(match range)
                       withString:<<-END-TEMPLATE
#{tagName})
(#{resultName} appendString:(or (#{(match groupAtIndex:1)} stringValue) ""))
(#{resultName} appendString:<<-#{tagName}
END-TEMPLATE))
          
          ;; next, replace all the nu code opens with string terminations
          (set p-open /<%/)
          (while (set match (p-open findInString:text))
                 (text replaceCharactersInRange:(match range)
                       withString:"#{tagName})"))
          
          ;; the last transformation replaces all the nu code closes with code to capture strings
          (set p-close /%>/)
          (while (set match (p-close findInString:text))
                 (text replaceCharactersInRange:(match range)
                       withString:"(#{resultName} appendString:<<-#{tagName}#{(NSString carriageReturn)}"))
          
          ;; All the text we've processed is now captured in a script.
          ;; This script can be evaluated to produce the desired output text.
          (set script "")
          (script appendString:<<-END-TEMPLATE
(let (#{resultName} "") 
(#{resultName} appendString:<<-#{tagName}
END-TEMPLATE)
          (script appendString: text)
          ;(set final-pattern (regex "#{tagName}$"))
          ;(if (final-pattern findInString:script) (script appendString:(NSString carriageReturn)))
          (script appendString:<<-END-TEMPLATE
#{tagName})
#{resultName})
END-TEMPLATE)
          script))
