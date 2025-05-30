import os
import sys

if len(sys.argv) > 1:
    network_path = sys.argv[1]
else:
    sys.exit("No network path specified!")
    network_path="networks/lateral_1"
    
modified_network_file=os.path.join(network_path, "network-synapses-minimal.hdf5")

print(f"Network_path = {network_path}, modified file = {modified_network_file}")

from snudda.utils.ablate_network import SnuddaAblateNetwork

ab = SnuddaAblateNetwork(network_file=network_path)
pop_unit_1 = ab.snudda_load.get_population_unit_members(population_unit=1)
pop_unit_2 = ab.snudda_load.get_population_unit_members(population_unit=2)
ab.only_keep_neuron_id(neuron_id=set(pop_unit_1).union(set(pop_unit_2)))
ab.write_network(out_file_name=modified_network_file)

