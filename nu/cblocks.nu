;; @file       cblocks.nu
;; @discussion Macros for creating C/Objective-C blocks from Nu
;; 
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

;; bridgedblock returns a NuBridgedBlock object that references a NuBlock and a corresponding C Block.
;; These can be obtained by sending the nuBlock and cBlock messages, respectively.  Use this when you
;; want to be able to call the block from Nu or pass it to an objective C method.  If you only care
;; about the C block, you can use the 'cblock' macro instead.
;;

(macro bridgedblock (ret params *body)
    (progn
        ; Bail if blocks aren't enabled in the framework
        (try ((NuBridgedBlock class)) 
            (catch (execption) (throw* "NuException" "This build of Nu does not support C blocks.")))
                
        (set __sig (signature (list ret)))
        (set __blockparams ())
        (set __paramlist params)
        (until (eq __paramlist nil)
            (set __type (car __paramlist))
            (if (eq (cdr __paramlist) nil) 
                (throw* "NuMatchException" 
                    "cblock parameter list must contain an even number of elements in the form \"(type) name\""))
            (set __param (car (cdr __paramlist)))
            (set __paramlist (cdr (cdr __paramlist)))
            (set __sig (__sig stringByAppendingString:
                (signature __type)))
            (set __blockparams (append __blockparams (list __param))))
        ;(puts "Signature: #{__sig}")
        ;(puts "Block params: #{__blockparams}")
        `(((NuBridgedBlock alloc) initWithNuBlock:
            (do ,__blockparams ,*body) signature:,__sig))))


(macro cblock (ret params *body) `((bridgedblock ,ret ,params ,*body) cBlock))
