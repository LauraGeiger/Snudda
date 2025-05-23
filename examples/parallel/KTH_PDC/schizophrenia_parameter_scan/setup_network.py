# This function needs to create WT network as base, then degenerates
# the morphologies as needed to create the diseased SZ networks.

import os
from snudda.place.create_cube_mesh import create_cube_mesh
from snudda import Snudda

ipython_profile = os.getenv("IPYTHON_PROFILE", "default")
ipython_dir = os.getenv("IPYTHONDIR")

parallel_flag = ipython_dir is not None


# Setup WT network

data_base_path = "/home/hjorth/HBP/szmod/snudda/snudda_data"
network_base_path = "networks"

# Base WT network
snudda_data_wt = os.path.join(data_base_path, "wt")

# List of SZ versions
snudda_data_d2oe = ["d2oe.1", "d2oe.2", "d2oe.3", "d2oe.4", "d2oe.5"]

# Create WT network

network_path_wt = os.path.join(network_base_path, "wt")

n_dSPN = 200
n_iSPN = 200
n_FS = 8

n_non_virtual = 100

neuron_paths = [os.path.join(snudda_data_wt, "neurons", "striatum", "dspn"),
                os.path.join(snudda_data_wt, "neurons", "striatum", "ispn"),
                os.path.join(snudda_data_wt, "neurons", "striatum", "fs")]

connectivity_info = os.path.join(snudda_data_wt, "connectivity", "striatum", "striatum-connectivity.json")

mesh_file = os.path.join("mesh", "cube_mesh.obj")
create_cube_mesh(file_name=mesh_file,
                 centre_point=(0, 0, 0),
                 side_len=(10000.0/80500)**(1/3)*0.001)

snd = Snudda(network_path=network_path_wt)
snd_init = snd.init_tiny(neuron_paths=neuron_paths,
                         neuron_names=["dSPN", "iSPN", "FS"], number_of_neurons=[n_dSPN, n_iSPN, n_FS],
                         connection_config=connectivity_info,
                         density=80500, d_min=15e-6,
                         snudda_data=snudda_data_wt, random_seed=123)

snd.create_network()

###### Set neurons to virtual

from snudda.utils.ablate_network import SnuddaAblateNetwork
from snudda.utils import SnuddaLoad

network_file_wt_virtual = os.path.join(network_path_wt, "wt-virtual-network.hdf5")

sa = SnuddaAblateNetwork(network_file=network_path_wt)
sl = sa.snudda_load
virtual_idx = sorted(list(set(sl.iter_neuron_id()) - set([x for x, _ in sl.get_centre_neurons_iterator(n_neurons=n_non_virtual)])))

sa.make_virtual(virtual_idx)
sa.write_network(network_file_wt_virtual)

######

# TODO: We need to create the network input, with 2 seconds background input followed by 8 steps, each 1 s, with random
#       frequency 0-10Hz.

snd.setup_input(input_config="input.json",
                network_file=network_file_wt_virtual)


# Create the D2OE networks

from snudda.utils.swap_to_degenerated_morphologies import SwapToDegeneratedMorphologies

for d2oe_name in snudda_data_d2oe:
    network_path_d2oe = os.path.join(network_base_path, d2oe_name)
    network_file_d2oe = os.path.join(network_path_d2oe, f"{d2oe_name}-network-synapses.hdf5")
    snudda_data_d2oe_path = os.path.join(data_base_path, d2oe_name)

    original_input_file = os.pat.join(network_path_wt, "input-spikes.hdf5")
    d2oe_input_file = os.path.join(network_path_d2oe, f"{d2oe_name}-input-spikes.hdf5")

    swap = SwapToDegeneratedMorphologies(original_network_file=network_file_wt_virtual,
                                         new_network_file=network_file_d2oe,
                                         original_snudda_data_dir=snudda_data_wt,
                                         new_snudda_data_dir=snudda_data_d2oe_path,
                                         original_input_file=original_input_file,
                                         new_input_file=d2oe_input_file)
    swap.write_new_network_file()
    swap.write_new_input_file(remap_removed_input=False)
    swap.close()


