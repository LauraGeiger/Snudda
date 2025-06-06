import argparse
import os
import glob
import json
import numpy as np
from snudda.utils import snudda_parse_path


class PurgeBadParameters:

    """ This code assumes you have manually moved all the figures
        corresponding to 'bad' parametersets to a 'bad' folder """

    def __init__(self, network_path, bad_figure_path, snudda_data=None):

        self.network_path = network_path
        self.bad_figure_path = bad_figure_path
        self.snudda_data = snudda_data
        self.bad_keys = dict()

    def process(self, update_files=True):

        self.get_bad_keys_in_dir(path=self.bad_figure_path)
        neuron_paths = self.load_network_config(network_path=self.network_path)
        self.purge_bad_parameters(neuron_paths=neuron_paths, update_files=update_files)

    def get_bad_keys_in_dir(self, path, file_extension=".png"):
        file_list = glob.glob(os.path.join(path, f"*{file_extension}"))

        for f in file_list:
            f_parts = os.path.basename(f).split("-")
            morph_key = f_parts[0]
            param_key = f_parts[1]

            if param_key not in self.bad_keys:
                self.bad_keys[param_key] = []

            self.bad_keys[param_key].append(morph_key)

    def load_network_config(self, network_path):

        network_config_path = os.path.join(network_path, "network-config.json")

        with open(network_config_path, "r") as f:
            self.network_config = json.load(f)

        if self.snudda_data is None:
            self.snudda_data = self.network_config["snudda_data"]

        neuron_paths = []

        for region_name, region_data in self.network_config["regions"].items():
            for neuron_name, neuron_data in region_data["neurons"].items():
                for name, path in neuron_data["neuron_path"].items():
                    neuron_paths.append(snudda_parse_path(path, self.snudda_data))

        return neuron_paths

    def purge_bad_parameters(self, neuron_paths, update_files=True):

        parsed_meta = []

        for neuron_path in neuron_paths:
            meta_file = os.path.join(neuron_path, "meta.json")

            if meta_file in parsed_meta:
                continue
            else:
                parsed_meta.append(meta_file)

            purge_counter = 0
            param_sets_left = 0

            with open(meta_file, "rt") as f:
                meta_data = json.load(f)

            print(f"Parsing {meta_file}")

            for param_key in list(meta_data.keys()):

                if param_key in self.bad_keys:
                    for morph_key in list(meta_data[param_key].keys()):
                        if morph_key in self.bad_keys[param_key]:
                            print(f"Removing {param_key = }, {morph_key = }")
                            del meta_data[param_key][morph_key]
                            purge_counter += 1

                if len(meta_data[param_key]) == 0:
                    print(f"--> No morphologies left for {param_key = }")
                    del meta_data[param_key]
                    meta_changed = True

            for param_key, param_data in meta_data.items():
                param_sets_left += len(param_data.keys())

            if purge_counter > 0 and update_files:
                print(f"Writing {meta_file} (purged {purge_counter} parameter sets, {param_sets_left} left)")
                with open(meta_file, "wt") as f:
                    json.dump(meta_data, f, indent=4)


def cli():

    import argparse
    parser = argparse.ArgumentParser(description="Purge the bad input parameters from meta.json")
    parser.add_argument("network_path", help="Path to network folder")
    parser.add_argument("bad_figure_path", help="Path to 'bad' figure folder")
    parser.add_argument("--snudda_data", type=str, default=None)
    parser.add_argument("--mock_run", action="store_true")
    args = parser.parse_args()

    pbp = PurgeBadParameters(network_path=args.network_path,
                             bad_figure_path=args.bad_figure_path,
                             snudda_data=args.snudda_data)
    pbp.process(update_files=not args.mock_run)


if __name__ == "__main__":
    cli()
