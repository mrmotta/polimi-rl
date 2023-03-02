#!/usr/bin/env python3

# +----------------------------------------------------+
# |                                                    |
# | Script realizzato da Riccardo Motta e Matteo Negro |
# |                                                    |
# +----------------------------------------------------+

import argparse
import os
import random

START_FILE = "tb_base.vhd"


def parse_input(solve):
    result = []
    solve = solve.split(' ')
    for string in solve:
        if not len(string) == 8:
            print('Input string has to be composed by bytes (8 bits)')
            exit(3)
        if not is_boolean(string):
            print('Input string has to be composed by bytes (binary arrays)')
            exit(4)
        result.append([int(char) for char in string])
    return result


def is_boolean(string):
    string_set = set(string)
    check_set = {'0', '1'}
    if string_set == check_set or string_set == {'0'} or string_set == {'1'}:
        return True
    else:
        return False


def get_random_byte():
    result = []
    for _ in range(0, 8):
        result.append(random.getrandbits(1))
    return result


def process(input_list):
    result = []
    state = 0
    input = []
    for index in range(0, len(input_list)):
        input += input_list[index]
    for index in range(0, len(input)):
        if state == 0:
            if input[index] == 0:
                state = 0
                result.append(0)
                result.append(0)
            else:
                state = 2
                result.append(1)
                result.append(1)
        elif state == 1:
            if input[index] == 0:
                state = 0
                result.append(1)
                result.append(1)
            else:
                state = 2
                result.append(0)
                result.append(0)
        elif state == 2:
            if input[index] == 0:
                state = 1
                result.append(0)
                result.append(1)
            else:
                state = 3
                result.append(1)
                result.append(0)
        else:
            if input[index] == 0:
                state = 1
                result.append(1)
                result.append(0)
            else:
                state = 3
                result.append(0)
                result.append(1)
    return [result[index: index + 8] for index in range(0, len(result), 8)]


def listToString(s):
    string = ""
    for el in s:
        string += str(el)
    return (string)


def print_data(input_length, input, output, file):
    if file is None:
        print()
        print('Test case')
        print('Length: ' + str(input_length) + ' bytes')
        print('Input:')
        print(format_list(input))
        print('Output:')
        print(format_list(output))
    else:
        with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), START_FILE), 'r') as fr:
            with open(file, 'w') as fw:
                for line in fr.readlines():
                    fw.write(line)
                    if "-- Ram instance" in line:
                        fw.write(f'    signal RAM: ram_type := (000      => std_logic_vector(to_unsigned({input_length}, 8)),\n')
                        for num, ins in enumerate(input):
                            fw.write(f'                            {num + 1 : 04d}      => "{listToString(ins)}",\n')
                    elif "-- Checking behaviour:" in line:
                        for num, ins in enumerate(output):
                            fw.write(f'        assert RAM({1000 + num}) = "{listToString(ins)}" report "UNSUCCESSFUL TEST: #{num : 04d} byte in RAM -> add: {1000 + num}; right value: {listToString(ins)}; found value: " & integer\'image(to_integer(unsigned(RAM({1000 + num})))) severity failure;\n')
                fw.close()
            fr.close()


def format_list(vector):
    tmp = []
    for index in range(0, len(vector)):
        tmp.append(''.join(map(str, vector[index])))
    return ' '.join(tmp)


if __name__ == '__main__':

    input = []
    output = []

    parser = argparse.ArgumentParser(description='A test case generator and solver for the project')
    parser.add_argument('--bytes', '-b', type=int, default=0, help='number of input bytes')
    parser.add_argument('--output', '-o', type=str, help='output file where to store data')
    parser.add_argument('--solve', '-s', type=str, help='input case to solve')
    args = parser.parse_args()

    if args.bytes < 0 or args.bytes > 255:
        print('The number of bytes has to be between 0 and 255, with 0 that means random in [1; 255]')
        exit(1)

    if args.bytes == 0:
        random_length = True
    else:
        random_length = False

    if args.output is not None:
        try:
            open(args.output, 'w').close()
        except Exception:
            print('Cannot open output file')
            exit(2)

    if args.solve is None:

        if random_length:
            args.bytes = random.randrange(1, 256)

        for _ in range(0, args.bytes):
            input.append(get_random_byte())

    else:
        input = parse_input(args.solve)

    for result in process(input):
        output.append(result)

    print_data(len(input), input, output, args.output)
