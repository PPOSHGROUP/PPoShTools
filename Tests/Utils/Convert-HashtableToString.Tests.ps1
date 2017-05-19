Import-Module -Name "$PSScriptRoot\..\..\PPoShTools\PPoShTools.psd1" -Force

Describe -Tag "PPoShTools" "Convert-HashtableToString" {
    InModuleScope PPoShTools {

        Context "When invoked for flat ordered hashtable" {
            $hash = [ordered]@{ 'testStr' = 'testValue1'; 'testInt' = 3 }
            $result = Convert-HashtableToString -Hashtable $hash
            
            It "should return proper hashtable" {
                $result | Should Be "@{'testStr'='testValue1'; 'testInt'='3'; }"
            }
        }

        Context "When invoked for nested ordered hashtable" {
            $hash = [ordered]@{ 'testStr' = 'testValue1'; 'testNested' = [ordered]@{ 'nest1' = 'abc'; 'nest2' = [ordered]@{ 'nest21' = 'abc'; 'nest22' = 'def' } } }
            $result = Convert-HashtableToString -Hashtable $hash
            
            It "should return proper hashtable" {
                $result | Should Be "@{'testStr'='testValue1'; 'testNested'=@{'nest1'='abc'; 'nest2'=@{'nest21'='abc'; 'nest22'='def'; }; }; }"
            }
        }

        Context "When invoked for nested hashtable" {
            $hash = [ordered]@{ 'test1' = @{ 'test2' = 'abc' } }
            $result = Convert-HashtableToString -Hashtable $hash
            
            It "should return proper hashtable" {
                $result | Should Be "@{'test1'=@{'test2'='abc'; }; }"
            }
        }
    }
}