include math.util.MathUtil

include test.executor.TestExecutor

MathUtilTest(){
	run(){
		TestExecutor executeTest math.util.test
	}

	testDecrement(){
		if [[ $(MathUtil decrement 2) == 1 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testDecrement[negative](){
		if [[ $(MathUtil decrement -1) == -2 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testDifference(){
		if [[ $(MathUtil difference 2 1) == 1 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testFormat[false](){
		if [[ $(MathUtil format 10) == 10 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testFormat[true](){
		if [[ $(MathUtil format 9) == 09 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testIncrement(){
		if [[ $(MathUtil increment 1) == 2 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testIncrement[negative](){
		if [[ $(MathUtil increment -1) == 0 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testIsDivisible[false](){
		if [[ ! $(MathUtil isDivisible 3 2) ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testIsDivisible[true](){
		if [[ $(MathUtil isDivisible 4 2) ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testIsEven[false](){
		if [[ ! $(MathUtil isEven 3) ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testIsEven[true](){
		if [[ $(MathUtil isEven 4) ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testIsOdd[false](){
		if [[ ! $(MathUtil isOdd 4) ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testIsOdd[true](){
		if [[ $(MathUtil isOdd 3) ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testModulus(){
		if [[ $(MathUtil modulus 4 2) == 0 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testProduct(){
		if [[ $(MathUtil product 2 3) == 6 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testProduct[identity](){
		if [[ $(MathUtil product 1 2) == 2 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testProduct[zero](){
		if [[ $(MathUtil product 0 3) == 0 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testQuotient(){
		if [[ $(MathUtil quotient 4 2) == 2 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testQuotient[cannot-divide-by-zero](){
		if [[ $(MathUtil quotient 1 0) =~ "Cannot divide by zero." ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testQuotient[floor](){
		if [[ $(MathUtil quotient 5 2 ) == 2 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testSum(){
		if [[ $(MathUtil sum 1 1) == 2 ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	$@
}