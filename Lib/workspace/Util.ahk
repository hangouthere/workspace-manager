#Include <JSON>

class Util
{
    class DoubleBind extends JSON.Functor {
        Call(self, origFunc, vals*) {
            fn := this._bindingFunc.Bind(this, origFunc, vals)

            return fn
        }

        _bindingFunc(origFunc, vals, finalVals*) {
            origFunc.Call(Util.ArrayConcat(vals, finalVals)*)
        }
    }

    class ArrayConcat extends JSON.Functor {
        Call(self, Arrs*) {
            FinalArray := []

            For idx, Arr in Arrs {
                for _idx, _Val in Arr {
                    FinalArray.push(_Val)
                }
            }

            return FinalArray
        }
    }

    class ArrayIsEmpty extends JSON.Functor {
        Call(self, val) {
            for _idx, _Val in val {
                return false
            }

            return true
        }
    }

    class ObjMerge extends JSON.Functor {
        Call(self, _Objs*) {
            FinalObj := []

            For objNum, _Obj in _Objs {
                for _Key, _Val in _Obj {
                    FinalObj[_Key] = _Val
                }
            }

            return FinalObj
        }
    }

    ; Function: Array_DeepClone
    ; Description: Deep clone
    ; Syntax: Arrary_DeepClone(Array)
    ; Parameters:
    ;    Param1 - Array
    ;    An array, associative array, or object.
    ; Return Value:
    ;    A copy of the array, that is not linked to the original
    ; Remarks:
    ;    Supports sub-arrays, and circular refrences
    ; Related:
    ;    Array_Gui, Array_Print, Array_IsCircle
    ; Example:
    ;    Array1 := {"A":["Aardvark", "Antelope"], "B":"Bananas"}
    ;    Array2 := Array_DeepClone(Array1)
    ;
    ; Originated from: https://autohotkey.com/board/topic/85201-array-deep-copy-treeview-viewer-and-more/

    class Array_DeepClone extends JSON.Functor {
        Call(self, Array, Objs=0)
        {
            if !Objs
                Objs := {}
            Obj := Array.Clone()
            Objs[&Array] := Obj ; Save this new array

            For Key, Val in Obj
            {
                ; If it is a subarray
                ; If we already know of a refrence to this array
                ; Then point it to the new array
                ; Otherwise, clone this sub-array
                if (IsObject(Val)) {
                    Obj[Key] := Objs[&Val] ? Objs[&Val] : Util.Array_DeepClone(Val, Objs)
                }
            }

            return Obj
        }
    }
}