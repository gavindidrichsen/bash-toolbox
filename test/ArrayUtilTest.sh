include array.util.ArrayUtil

include test.executor.TestExecutor

ArrayUtilTest(){
	run(){
		local tests=(
			appendArrayEntry
			bisect[false]
			bisect[true]
			convertStringToArray
			flipArray
			partition[1-of-3]
			partition[2-of-3]
			partition[3-of-3]
			returnMaxLength
			strip
		)

		TestExecutor executeTest ArrayUtilTest ${tests[@]}
	}

	testAppendArrayEntry(){
		local inputArray=(foo foobar)
		local outputArray=(foo... foobar)

		if [[ $(ArrayUtil
			appendArrayEntry ${inputArray[@]}) == ${outputArray[@]} ]]; then

			echo PASS
		else
			echo FAIL
		fi
	}

	testBisect[false](){
		local inputArray=(1 2 3 4 5 6)
		local outputArray=(4 5 6)

		if [[ $(ArrayUtil
			bisect false ${inputArray[@]}) == ${outputArray[@]} ]]; then

			echo PASS
		else
			echo FAIL
		fi
	}

	testBisect[true](){
		local inputArray=(1 2 3 4 5 6)
		local outputArray=(1 2 3)

		if [[ $(ArrayUtil
			bisect true ${inputArray[@]}) == ${outputArray[@]} ]]; then

			echo PASS
		else
			echo FAIL
		fi
	}

	testConvertStringToArray(){
		local input="foo,bar"
		local output="foo bar"

		if [[ $(ArrayUtil convertStringToArray ${input}) == ${output} ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	testFlipArray(){
		local inputArray=(foo bar)
		local outputArray=(bar foo)

		if [[ $(ArrayUtil
			flipArray ${inputArray[@]}) == ${outputArray[@]} ]]; then

			echo PASS
		else
			echo FAIL
		fi
	}

	testPartition[1-of-3](){
		local inputArray=(1 2 3 4 5 6)
		local outputArray=(1 2)

		if [[ $(ArrayUtil
			partition 3 1 ${inputArray[@]}) == ${outputArray[@]} ]]; then

			echo PASS
		else
			echo FAIL
		fi
	}

	testPartition[2-of-3](){
		local inputArray=(1 2 3 4 5 6)
		local outputArray=(3 4)

		if [[ $(ArrayUtil
			partition 3 2 ${inputArray[@]}) == ${outputArray[@]} ]]; then

			echo PASS
		else
			echo FAIL
		fi
	}

	testPartition[3-of-3](){
		local inputArray=(1 2 3 4 5 6)
		local outputArray=(5 6)

		if [[ $(ArrayUtil
			partition 3 3 ${inputArray[@]}) == ${outputArray[@]} ]]; then

			echo PASS
		else
			echo FAIL
		fi
	}

	testReturnMaxLength(){
		local inputArray=(foo foobar)
		local maxLength=6

		if [[ $(ArrayUtil
			returnMaxLength ${inputArray[@]}) == ${maxLength} ]]; then

			echo PASS
		else
			echo FAIL
		fi
	}

	testStrip(){
		local inputArray=(foo foo bar bar)

		if [[ $(ArrayUtil strip ${inputArray[@]} foo) == "bar bar" ]]; then
			echo PASS
		else
			echo FAIL
		fi
	}

	$@
}