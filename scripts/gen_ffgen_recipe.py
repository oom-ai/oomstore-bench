#!/usr/bin/env python

import itertools
import sys
import yaml


def group_gen():
    for i in itertools.count(start=1):
        match i % 10:
            case x if x <= 5:
                yield {
                    'name': f"feature_{i}",
                    'rand_gen': {
                        'type': 'int',
                        'start': 0,
                        'end': 1000000,
                    }
                }
            case(6 | 7):
                yield {
                    'name': f"feature_{i}",
                    'rand_gen': {
                        'type': 'bool',
                        'prob': 0.5,
                    }
                }
            case(8):
                yield {
                    'name': f"feature_{i}",
                    'rand_gen': {
                        'type': 'float',
                        'start': 0.00,
                        'end': 1000.00,
                    }
                }
            case(9):
                yield {
                    'name': f"feature_{i}",
                    'rand_gen': {
                        'type': 'enum',
                        'values': ['Red', 'Green', 'Blue']
                    }
                }

def main():
    count = int(sys.argv[1])
    recipe = {
        'entity': {
            'name': 'bench',
        },
        'groups': [{
            'name': f"group_size_{count}",
            'features': list(itertools.islice(group_gen(), count)),
        }],
    }
    print(yaml.dump(recipe, sort_keys=False))

if __name__ == "__main__":
    main()
