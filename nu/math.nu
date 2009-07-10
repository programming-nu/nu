;; @file       math.nu
;; @discussion Basic math functions.
;;
;; @copyright  Copyright (c) 2008 Issac Trotts
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

;; Evaluates the exponential function exp(x) = e^x on a floating point number.
(global exp
        (do (x)
            (NuMath exp:x)))

;; Returns two to the power of a floating point number.
(global exp2
        (do (x)
            (NuMath exp2:x)))

;; Returns the trigonometric cosine of a floating point number.
(global cos
        (do (x)
            (NuMath cos:x)))

;; Returns the trigonometric sine of a floating point number.
(global sin
        (do (x)
            (NuMath sin:x)))

;; Returns the square root of a floating point number.
(global sqrt
        (do (x)
            (NuMath sqrt:x)))

;; Returns the cube root of a floating point number.
(global cbrt
        (do (x)
            (NuMath cbrt:x)))

;; Returns the natural logarithm of a floating point number.
(global log
        (do (x)
            (NuMath log:x)))

;; Returns the base two logarithm of a floating point number.
(global log2
        (do (x)
            (NuMath log2:x)))

;; Returns the base ten logarithm of a floating point number.
(global log10
        (do (x)
            (NuMath log10:x)))

;; Returns the absolute value of a floating point number.
(global abs
        (do (x)
            (NuMath abs:x)))

;; Returns the greatest integer <= a floating point number.
(global floor
        (do (x)
            (NuMath floor:x)))

;; Returns the least integer >= a floating point number.
(global ceil
        (do (x)
            (NuMath ceil:x)))

;; Returns the nearest integer to a floating point number.
(global round
        (do (x)
            (NuMath round:x)))

;; Returns x raised to the power of y.
(global pow
        (do (x y)
            (NuMath raiseNumber:x toPower:y)))

