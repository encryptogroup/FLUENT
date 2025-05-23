#include "valiantMerged.h"
#include <unordered_map>
#include <math.h>
#include <cassert>
#include <algorithm>
#include "../../gamma/gamma.h"



// Removes a single occurence of an element from a multiset
template<class T>
void remove_single(unordered_multiset<T>& uset, T elem) {
    auto it = uset.find(elem);
    if (it != uset.end()) {
        uset.erase(it);
    }
}

// Returns a (possibly) padded function bits vector, such that the function stays the same and ignore the last inputs (i.e. the added dummy inputs)
vector<int> set_function_bits(vector<int> &function_bits, size_t n){
    size_t current_size = function_bits.size();
    if (function_bits.empty()){
        return function_bits;
    }
    int curr_arity = log2(current_size);
    int nr_of_copies = pow(2, n - curr_arity);
    assert(nr_of_copies > 0);
    if (nr_of_copies <= 1){
        return function_bits; // no padding needed
    }
    vector<int> new_function_bits;
    for(size_t i = 0; i < current_size; i++){
        int entry = function_bits[i];
        for (int j=0; j < nr_of_copies; j++){
            new_function_bits.push_back(entry);
        }
    }
    return new_function_bits;
}

ValiantMerged::Node::Node(ValiantMerged::Node* k_input_pole, string dis_range, string con_range) {
    number = -1;
    type = "gate";
    is_pole = true;
    this->eug_number = 0;
    position = "";
    identifier = k_input_pole->identifier + "_" + dis_range + "_" + con_range;
    control_bit = 2;
    is_k_input = false;
}

ValiantMerged::Node::Node(ValiantBase::Node* node, int eug_number) {
    number = node->number;
    type = node->type;
    is_pole = node->is_outest_pole;
    this->eug_number = eug_number;
    position = node->position;
    identifier = to_string(eug_number) + node->identifier;
    control_bit = node->control_bit;
    is_k_input = node->is_k_input;
}


void ValiantMerged::add_edge(ValiantMerged::Node* from, ValiantMerged::Node* to, bool from_side, bool to_side) {
    ValiantMerged::Edge* e = new ValiantMerged::Edge(from, to, from_side, to_side);
    from->out_edges.push_back(e);
    to->in_edges.push_back(e);
}

ValiantMerged::ValiantMerged() {};

ValiantMerged::ValiantMerged(vector<ValiantBase*> gamma1_eugs) {
    // Create merged poles
    for (ValiantBase::Node* pole : gamma1_eugs[0]->poles) {
        ValiantMerged::Node* corr_pole = new ValiantMerged::Node(pole, 0);
        poles.push_back(corr_pole);
        vertices.push_back(corr_pole);
    }

    int eug_number = 1;
    for (ValiantBase* gamma1_eug : gamma1_eugs) {
        merge_graph(gamma1_eug, eug_number++);
    }

}

void ValiantMerged::merge_graph_rec(ValiantBase* gamma1_eug, ValiantBase::Node* curr, unordered_set<ValiantBase::Node*>& visited, int eug_number) {
    if (visited.find(curr) != visited.end()) {
        return;
    }
    visited.insert(curr);
    get_corresponding_vertex(curr, eug_number);
    for (ValiantBase::Edge* e_out : curr->out_edges) {
        convert_edge(e_out->from, e_out->to, e_out->from_side, e_out->to_side, eug_number);
        if (visited.find(e_out->to) == visited.end()) {
            merge_graph_rec(gamma1_eug, e_out->to, visited, eug_number);
        }
    }
}

void ValiantMerged::merge_graph(ValiantBase* gamma1_eug, int eug_number) {
    unordered_set<ValiantBase::Node*> visited;
    // Use that our graph is reachable from the first pole
    merge_graph_rec(gamma1_eug, gamma1_eug->poles[0], visited, eug_number);
}

void ValiantMerged::convert_edge(ValiantBase::Node* from, ValiantBase::Node* to, bool from_side, bool to_side, int eug_number) {
    //Check whether the corresponding nodes already exist and possibly create them
    ValiantMerged::Node* from_merged = get_corresponding_vertex(from, eug_number);
    ValiantMerged::Node* to_merged = get_corresponding_vertex(to, eug_number);
    add_edge(from_merged, to_merged, from_side, to_side);
}

// Returns the corresponding merged vertex. If there was none, the corresponding merged vertex will be created.
ValiantMerged::Node* ValiantMerged::get_corresponding_vertex(ValiantBase::Node* vertex, int eug_number) {
    if (vertex->is_outest_pole) {
        return poles[vertex->number - 1];
    }
    else {
        ValiantMerged::Node* corr_vertex;
        if (node_mapping.find(vertex) == node_mapping.end()) {
            corr_vertex = new ValiantMerged::Node(vertex, eug_number);
            vertices.push_back(corr_vertex);
            node_mapping[vertex] = corr_vertex;
        }
        else {
            corr_vertex = node_mapping[vertex];
        }
        return corr_vertex;
    }
}

void ValiantMerged::print_graph() {
    ofstream os;
    os.open("graphviz/merged");
    os << "digraph{\n";
    print_vertices(os);
    unordered_set<ValiantMerged::Node*> visited;
    // Graph must be reachable from starting pole
    //print_graph_rec(poles[0], visited, os);
    for (ValiantMerged::Node* vertex : poles) {
        print_graph_rec(vertex, visited, os);
    }
    os << "}";
    os.close();
}

void ValiantMerged::print_graph_rec(ValiantMerged::Node* curr, unordered_set<ValiantMerged::Node*>& visited, ofstream& os) {
    if (visited.find(curr) != visited.end()) {
        // vertex already visited
        return;
    }
    visited.insert(curr);
    for (ValiantMerged::Edge* e : curr->out_edges) {
        e->print_edge(os);
        if (visited.find(e->to) == visited.end()) {
            print_graph_rec(e->to, visited, os);
        }
    }
}

void ValiantMerged::Edge::print_edge(ofstream& os) {
    string side = "";
    if (to->is_pole) {
        side += to_string(from->eug_number);
    }
    if (from_side) {
        side += "l";
    }
    else {
        side += "r";
    }
    if (to_side) {
        side += "l";
    }
    else {
        side += "r";
    }
    string side_label = " [ label = \"" + side + "\" ] ";
    os << "\"" << from->identifier << "\"" << " -> " << "\"" << to->identifier << "\"" << side_label << "\n";
}

void ValiantMerged::print_vertices(ofstream& os) {
    for (ValiantMerged::Node* curr : vertices) {
        os << "node " << curr->get_style() << " \"" << curr->identifier << "\";\n";
    }
}

string ValiantMerged::Node::get_style() {
    if (type == "x") {
        if (control_bit == 0) {
            return "[ style=filled,fillcolor=\"red\" ]";
        }
        else if (control_bit == 1) {
            return "[ style=filled,fillcolor=\"magenta\" ]";
        }
        else {
            return "[ style=filled,fillcolor=\"orange\" ]";
        }
    }
    else if (type == "y") {
        if (control_bit == 0) {
            return "[ style=filled,fillcolor=\"blue\" ]";
        }
        else if (control_bit == 1) {
            return "[ style=filled,fillcolor=\"cyan\" ]";
        }
        else {
            return "[ style=filled,fillcolor=\"purple\" ]";
        }
    }
    else if (type == "copy") {
        return "[ style=filled,fillcolor=\"gray33\" ]";
    }
    else if (type == "gate") {
        return "[ style=filled,fillcolor=\"yellow\" ]";
    }
    else if (type == "input") {
        return "[ style=filled,fillcolor=\"green\" ]";
    }
    else if (type == "output") {
        return "[ style=filled,fillcolor=\"darkgreen\" ]";
    }
    else {
        return "[ style=filled,fillcolor=\"gray\" ]";
    }
}

/*
Replaces all wires from or to copy gates by direct wires.
*/
void ValiantMerged::remove_copy_gates() {
    for (ValiantMerged::Node* gate : vertices) {
        if (gate->type == "copy") {
            ValiantMerged::Edge* e_in = gate->in_edges[0]; // copy gates have only one input
            ValiantMerged::Node* v_in = e_in->from;
            bool from_side = e_in->from_side;
            remove_edge(e_in);
            for (ValiantMerged::Edge* e_out : gate->out_edges) {
                ValiantMerged::Node* v_out = e_out->to;
                bool to_side = e_out->to_side;
                add_edge(v_in, v_out, from_side, to_side);
                remove_edge(e_out);
            }
        }
    }
}

ValiantMerged::Edge* ValiantMerged::Edge::get_predecessor() {
    ValiantMerged::Node* predecessor = from;
    if (predecessor->type == "gate" || predecessor->type == "output" || predecessor->type == "input") {
        return 0;
    }
    else if (predecessor->type == "x" || predecessor->type == "y") {
        if (predecessor->control_bit != 0 && predecessor->control_bit != 1) {
            cout << "control bit not set" << endl;
            return 0;
        }
        // There are always only 2 incoming edges into an x or y switch
        for (ValiantMerged::Edge* e_in : predecessor->in_edges) {
            if ((predecessor->control_bit == 0) && (e_in->to_side == from_side)) {
                return e_in;
            }
            else if ((predecessor->control_bit == 1) && (e_in->to_side != from_side)) {
                return e_in;
            }
        }
        return 0;
    }
    else if (predecessor->type == "copy") {
        return predecessor->in_edges[0];
    }
    else if (predecessor->type == "forwarding") {
        return predecessor->get_in_edge(from_side);
    }
    cerr << "type not known" << endl;
    return 0;
}

ValiantMerged::Edge* ValiantMerged::Edge::find_input_rec() {
    ValiantMerged::Edge* predecessor = get_predecessor();
    if (predecessor) {
        return predecessor->find_input_rec();
    }
    else {
        // There is no predecessor, so return last edge
        return this;
    }
}

// Returns a vector of all poles that are routed to this pole, i.e. the programming bits are set in such a way that there is a path from the returned poles to this pole
vector<ValiantMerged::Node*> ValiantMerged::Node::find_inputs() {
    vector<ValiantMerged::Node*> results;
    for (ValiantMerged::Edge* e_in : in_edges) {
        ValiantMerged::Node* input = find_input(e_in);
        // Only return poles
        if (input && input->is_pole) {
            results.push_back(input);
        }
    }
    return results;
}

// Returns the pole that is mapped by the edge embedding to this pole using this edge
// Returns null pointer, if input is not a pole
ValiantMerged::Node* ValiantMerged::Node::find_input(ValiantMerged::Edge* e_in) {
    ValiantMerged::Edge* last_edge = e_in->find_input_rec();
    if (last_edge->from->is_pole) {
        return last_edge->from;
    }
    else {
        return 0;
    }
}


tuple<vector<ValiantMerged::Edge*>::iterator, vector<ValiantMerged::Edge*>::iterator> ValiantMerged::remove_edge(ValiantMerged::Edge* e) {
    int removed = 0;
    vector<ValiantMerged::Edge*>::iterator ret_it_1;
    for (vector<ValiantMerged::Edge*>::iterator it = e->to->in_edges.begin(); it != e->to->in_edges.end();) {
        if (*it == e) {
            it = e->to->in_edges.erase(it);
            ret_it_1 = it;
            removed++;
        }
        else {
            it++;
        }
    }
    assert(removed == 1);
    removed = 0;
    vector<ValiantMerged::Edge*>::iterator ret_it_2;
    for (vector<ValiantMerged::Edge*>::iterator it = e->from->out_edges.begin(); it != e->from->out_edges.end();) {
        if (*it == e) {
            it = e->from->out_edges.erase(it);
            ret_it_2 = it;
            removed++;
        }
        else {
            it++;
        }
    }

    assert(removed == 1);

    return make_tuple(ret_it_1, ret_it_2);
}

ValiantMerged::Edge::Edge(ValiantMerged::Node* from, ValiantMerged::Node* to, bool from_side, bool to_side) {
    this->from = from;
    this->to = to;
    this->from_side = from_side;
    this->to_side = to_side;
}


/*
Checks if all the edges from the graph to be embedded are mapped to correct paths in the EUG.
*/
bool ValiantMerged::check_correctness(DAG* base_graph) {
    unordered_map<int, int> pole_mapping;
    for (DAG::Node* v : base_graph->vertices) {
        pole_mapping[v->number] = v->number;
    }
    return check_correctness(base_graph, pole_mapping);
}

/*
Checks if all the edges from the graph to be embedded are mapped to correct paths in the EUG.
*/
bool ValiantMerged::check_correctness(DAG* base_graph, unordered_map<int, int>& pole_mapping) {
    bool success = true;

    // Get all the edges that need to be embedded
    unordered_map<int, unordered_set<int>> inputs;
    for (DAG::Node* curr : base_graph->vertices) {
        for (DAG::Edge* e_in : curr->in_edges) {
            inputs[pole_mapping[curr->number]].insert(pole_mapping[e_in->from->number]);
        }
    }

    // Now find the inputs of each pole by taking the reverse path and check if the paths correspond to the desired edges
    for (unsigned int i = 1;i < base_graph->vertices.size() + 1;i++) {
        if (inputs.find(pole_mapping[i]) != inputs.end()) {
            vector<ValiantMerged::Node*> results = poles[pole_mapping[i] - 1]->find_inputs();
            for (ValiantMerged::Node* input : results) {
                if (inputs[pole_mapping[i]].find(input->number) == inputs[pole_mapping[i]].end()) {
                }
                inputs[pole_mapping[i]].erase(input->number);
            }
            if (!inputs[pole_mapping[i]].empty()) {
                cout << "set not empty:" << endl;
                success = false;
                for (int elem : inputs[pole_mapping[i]]) {
                    cout << elem << " was not mapped to " << pole_mapping[i] << endl;
                }
            }
        }
    }
    return success;
}

/*
Sets random control bits to all x and y switches that are not set yet, i.e. that are not needed for the routing
but have to be set in order to hide the topology. Note that in real world a cryptographically secure PRG should
be used.
*/
void ValiantMerged::set_random_control_bits() {
    for (ValiantMerged::Node* vertex : vertices) {
        if (vertex->type == "x" || vertex->type == "y") {
            if (vertex->control_bit != 0 && vertex->control_bit != 1) {
                vertex->control_bit = rand() % 2; // note that in real world a cryptographically secure PRG should be used
            }
        }
    }
}

void ValiantMerged::topo_sort() {
    unordered_set<ValiantMerged::Node*> visited;
    list<ValiantMerged::Node*> sorting;
    list<ValiantMerged::Node*> result;
    // We need to start with the input vertices due to circuit output file restrictions
    for (ValiantMerged::Node* vertex : poles) {
        if (vertex->type == "input") {
            result.push_back(vertex);
        }
    }
    // Start actual sorting here
    for (ValiantMerged::Edge* e_out : poles[0]->out_edges) {
        e_out->to->topo_sort(visited, sorting);
    }
    int i = 0;
    for (ValiantMerged::Node* curr : sorting) {
        result.push_back(curr);
    }
    for (ValiantMerged::Node* vertex : poles) {
        if (vertex->type == "output") {
            result.push_back(vertex);
        }
    }
    for (ValiantMerged::Node* curr : result) {
        curr->top_order = i++;
    }
    topo_sorting = result;
}

void ValiantMerged::Node::topo_sort(unordered_set<ValiantMerged::Node*>& visited, list<ValiantMerged::Node*>& sorting) {
    if (type == "input" || type == "output") {
        // ignore these, since these will be treated extra
        return;
    }
    visited.insert(this);
    for (ValiantMerged::Edge* e_out : out_edges) {
        ValiantMerged::Node* child = e_out->to;
        if (child && (visited.find(child) == visited.end())) {
            child->topo_sort(visited, sorting);
        }
    }
    sorting.push_front(this);
}



/*
Creates the ABY circuit file and programming for this EUG and the graph to be embedded.
*/
void ValiantMerged::create_circuit_files() {
    ofstream circuit_os;
    ofstream programming_os;
    circuit_os.open("outputs/circuit");
    programming_os.open("outputs/programming");

    topo_sort();
    int index = 0; // additional wires
    unordered_map<ValiantMerged::Edge*, int> mapping; // maps each used edge in the EUG, to the corresponding wire in the UC
    bool finished_inputs = false;
    bool started_outputs = false;
    circuit_os << "C ";
    for (ValiantMerged::Node* curr : topo_sorting) {
        if (curr->type == "input") {
            for (ValiantMerged::Edge* e_out : curr->out_edges) {
                mapping[e_out] = index;
            }
            circuit_os << index << " ";
            index++;
        }
        else if (finished_inputs == false) {
            circuit_os << "\n";
            finished_inputs = true;
        }

        if (curr->type == "x" || curr->type == "y") {
            int input1 = mapping[curr->get_in_edge(true)];
            int input2 = mapping[curr->get_in_edge(false)];
            if (curr->type == "x") {
                for (ValiantMerged::Edge* e_out : curr->out_edges) {
                    int shift = (e_out->from_side) ? 0 : 1;
                    mapping[e_out] = index + shift;
                }
                circuit_os << "X " << input1 << " " << input2 << " " << index << " " << index + 1 << "\n";
                programming_os << curr->control_bit << "\n";
                index += 2;
            }
            else {
                // type is y
                for (ValiantMerged::Edge* e_out : curr->out_edges) {
                    mapping[e_out] = index;
                }
                circuit_os << "Y " << input1 << " " << input2 << " " << index << "\n";
                programming_os << curr->control_bit << "\n";
                index++;
            }
        }
        else if (curr->type == "gate") {
            vector<int> inputs;
            for (ValiantMerged::Edge* e_in : curr->in_edges) {
                inputs.push_back(mapping[e_in]);
            }
            for (ValiantMerged::Edge* e_out : curr->out_edges) {
                mapping[e_out] = index;
            }
            circuit_os << "U";
            for (int val : inputs) {
                circuit_os << " " << val;
            }
            circuit_os << " " << index << "\n";
            for(int bit: curr->function_bits){
                programming_os << bit << " ";
            }
            programming_os << "\n";
            index++;
        }

        if (curr->type == "output") {
            if (!started_outputs) {
                started_outputs = true;
                circuit_os << "O";
            }
            int output = mapping[curr->in_edges[curr->control_bit]];
            circuit_os << " " << output;
        }
    }
    circuit_os.close();
    programming_os.close();
}

/*
Removes edges to input poles, since they will never be used and adjusts the correspoding inputs to this input pole, i.e. if
it is an x switch, it will become a y switch afterwards.
*/
void ValiantMerged::remove_input_edges() {
    for (ValiantMerged::Node* vertex : poles) {
        if (vertex->type == "input") {
            for (ValiantMerged::Edge* e_in : vertex->in_edges) {
                if (e_in->from->type == "x") {
                    e_in->from->type = "y";
                }
            }
            clear_in_edges(vertex);
        }
    }
}


ValiantMerged::Edge* ValiantMerged::Node::get_in_edge(bool side) {
    ValiantMerged::Edge* result;
    bool flag = false;
    for (ValiantMerged::Edge* e_in : in_edges) {
        if ((side && e_in->to_side) || (!side && !e_in->to_side)) {
            if (flag) {
                cerr << "There is more than one incoming edge per side" << endl;
            }
            flag = true;
            result = e_in;
        }
    }
    return result;
}

ValiantMerged::Edge* ValiantMerged::Node::get_out_edge(bool side) {
    ValiantMerged::Edge* result = 0;
    bool flag = false;
    for (ValiantMerged::Edge* e_out : out_edges) {
        if ((side && e_out->from_side) || (!side && !e_out->from_side)) {
            if (flag) {
                cerr << "There is more than one outgoing edge per side" << endl;
            }
            flag = true;
            result = e_out;
        }
    }
    return result;
}

/*
In ABY format the outgoing wire of a y switch is the right input if the control bit is 0 and the left input
if the control bit is 1, i.e. :
control_bit = 0 => output right wire
control_bit = 1 => output left wire
So far we have treated a y switch like an x switch depending on the side of the output wire.
This function changes the control bit of the y switches as it must be in ABY.
*/
void ValiantMerged::transform_y_switches() {
    for (ValiantMerged::Node* vertex : vertices) {
        if (vertex->type == "y") {
            vertex->transform_y_switch();
        }
    }
}

/*
Helper function for transform_y_switches. We fix the output wire to be starting from the right and adjust
the control bit to it. Then this is in line with ABY format.
*/
void ValiantMerged::Node::transform_y_switch() {
    assert(type == "y");
    assert(!get_out_edge(true) || !get_out_edge(false));
    if (get_out_edge(true)) {
        // This means we only have left outgoing wires, transform them to right
        for (ValiantMerged::Edge* e_out : out_edges){
            e_out->from_side = false;
            control_bit = (control_bit + 1) % 2;
        }
    }
}

/*
Does some preprocessing to the EUG such that it can be easily transformed into the ABY format. No vertices are
removed, but some are changed and possibly become isolated vertices.
*/
void ValiantMerged::transform_to_ABY_format() {
    optimize_x_switches(); // Replace uneccessary x switches
    remove_copy_gates();    // Replace copy gates by wires
    set_random_control_bits();
    remove_input_edges();   // Replace edges to input poles
    transform_y_switches(); // Make y switches ABY compatible
}

/*
x switches that only have one input can be changed to copy gates, which will then later be replaced by direct wires.
*/
void ValiantMerged::optimize_x_switches() {
    for (ValiantMerged::Node* vertex : vertices) {
        if (vertex->type == "x") {
            if (vertex->in_edges.size() == 1 && vertex->out_edges.size() == 2) {
                vertex->type = "copy";
            }
        }
    }
}

/*
Removes all isolated vertices.
*/
void ValiantMerged::remove_zero_degree_vertices() {
    int count = 0;
    vector <ValiantMerged::Node*>::iterator it;
    for (it = vertices.begin(); it != vertices.end();) {
        ValiantMerged::Node* v = *it;
        if (v->in_edges.size() == 0 && v->out_edges.size() == 0 && v->type != "input") {
            it = vertices.erase(it);
            count++;
        }
        else {
            it++;
        }
    }
    cout << "Removed " << count << " zero degree vertices!" << endl;
}

/*
Replaces removes the edges of all forarding poles for each k input pole and replaces them with direct edges from the
inputs of the forwarding pole to the k input pole. At the end all forwarding poles are isolated vertices or y switches, if there is only one output and 2 inputs.
*/
void ValiantMerged::prepare_k_input(DAG* g, DAG* gx_old, unordered_map<int, int>& pole_mapping, unordered_map<int, vector<int>> &forwarding_poles) {
    for (pair<int, int> entry : pole_mapping) {
        if (forwarding_poles.find(entry.second) != forwarding_poles.end()) {
            // This means our node is a multi input gate
            ValiantMerged::Node* multi_input_pole = poles[entry.second - 1];
            vector<int> dag_forwarding_pole_nrs = forwarding_poles[entry.second];
            vector<ValiantMerged::Node*> curr_forwarding_poles;
            for (int forwarding_pole_nr : dag_forwarding_pole_nrs) {
                curr_forwarding_poles.push_back(poles[forwarding_pole_nr - 1]);
            }
            for (ValiantMerged::Node* f_pole : curr_forwarding_poles) {
                // The current out edges are not needed, they will be replaced by an edge to the corresponding multi input gate
                clear_out_edges(f_pole);
            }

            // Replace the forwarding pole by edges (the forwarding pole then is an isolated vertex and will be removed later)
            for (ValiantMerged::Node* f_pole : curr_forwarding_poles) {
                // These are all currently supported combinations. All combinations up to 5 inputs are supported.
                if((f_pole->num_inputs == 1 && f_pole->in_edges.size() == 3) || (f_pole->num_inputs == 1 && f_pole->in_edges.size() == 2)
                    || (f_pole->num_inputs == 2 && f_pole->in_edges.size() == 3) || (f_pole->num_inputs == 1 && f_pole->in_edges.size() == 4)
                    || (f_pole->num_inputs == 2 && f_pole->in_edges.size() == 4) || (f_pole->num_inputs == 3 && f_pole->in_edges.size() == 4)
                    || (f_pole->num_inputs == 1 && f_pole->in_edges.size() == 5) || (f_pole->num_inputs == 2 && f_pole->in_edges.size() == 5)
                    || (f_pole->num_inputs == 3 && f_pole->in_edges.size() == 5) || (f_pole->num_inputs == 4 && f_pole->in_edges.size() == 5)){
                    construct_hybrid_auxiliary_pole(f_pole,multi_input_pole, g);
                } else{
                    for (ValiantMerged::Edge* e_in : f_pole->in_edges) {
                        ValiantMerged::Node* from = e_in->from;
                        bool from_side = e_in->from_side;
                        add_edge(from, multi_input_pole, from_side, true);
                    }
                    clear_out_edges(f_pole);
                    clear_in_edges(f_pole);
                }
            }
        }
    }
    set_pole_information(gx_old, pole_mapping);
}

void ValiantMerged::clear_in_edges(ValiantMerged::Node* vertex) {
    for (auto it = vertex->in_edges.begin(); it != vertex->in_edges.end();) {
        it = get<0>(remove_edge(*it));
    }
}

void ValiantMerged::clear_out_edges(ValiantMerged::Node* vertex) {
    for (auto it = vertex->out_edges.begin(); it != vertex->out_edges.end();) {
        it = get<1>(remove_edge(*it));
    }
}


void ValiantMerged::set_pole_information(DAG* g) {
    for (DAG::Node* g_pole : g->vertices) {
        ValiantMerged::Node* pole = poles[g_pole->number - 1];
        pole->num_inputs = g_pole->in_edges.size();
    }
}

void ValiantMerged::set_pole_information(DAG* g, unordered_map<int, int>& pole_mapping) {
    for (DAG::Node* g_pole : g->vertices) {
        int new_pole_nr = pole_mapping[g_pole->number];
        ValiantMerged::Node* pole = poles[new_pole_nr - 1];
        pole->num_inputs = g_pole->in_edges.size();
    }
}

// Returns basic information about the UC like the number of needed AND gates and the distribution of the used gate input sizes
pair<vector<size_t>,vector<unsigned long>> ValiantMerged::show_stats(unsigned int mergings, bool inplace) {
    unsigned int total_uc_size = 0;
    unsigned int max_degree = 0;
    for (ValiantMerged::Node* v : vertices) {
        if (v->type == "gate" && v->in_edges.size() > max_degree) {
            max_degree = v->in_edges.size();
        }
    }
    int input_nodes = 0;
    int output_nodes = 0;
    int x_nodes = 0;
    int y_nodes = 0;
    vector<unsigned long> universal_gates(max_degree + 1, 0);
    int other_nodes = 0;
    for (ValiantMerged::Node* v : vertices) {
        if (v->type == "input") {
            input_nodes++;
        }
        else if (v->type == "output") {
            output_nodes++;
        }
        else if (v->type == "gate") {
            universal_gates[v->in_edges.size()] = universal_gates[v->in_edges.size()] + 1;

        }
        else if (v->type == "x") {
            x_nodes++;
        }
        else if (v->type == "y") {
            y_nodes++;
        }
        else {
            other_nodes++;
        }
    }
    assert(other_nodes == 0);
    cout << "Input nodes: " << input_nodes << "\n";
    cout << "Output nodes: " << output_nodes << "\n";
    cout << "X nodes: " << x_nodes << "\n";
    total_uc_size += 1 * x_nodes;
    cout << "Y nodes: " << y_nodes << "\n";
    total_uc_size += 1 * y_nodes;
    unsigned int gate_size = 0;
    vector<unsigned long> gate_sizes(max_degree + 1,0);
    for (unsigned int i = 0; i < universal_gates.size(); i++) {
        if (i <= mergings) {
            gate_size = pow(2, mergings) - 1;
            total_uc_size += gate_size * universal_gates[i];
        }
        else {
            gate_size = pow(2, i) - 1;
            total_uc_size += gate_size * universal_gates[i];
        }
        gate_sizes[i] = gate_size;
        cout << "Universal gates with " << i << " inputs (and size " << gate_size << ")" << ": " << universal_gates[i] << "\n";
    }
    cout << "EUG size is: " << vertices.size() << "\n";
    cout << "Total UC size is: " << total_uc_size << "\n";
    if (false && !inplace) {
        total_uc_size = x_nodes + 1 * y_nodes;
        int overhead = 0;
        for (unsigned int i = 0; i < universal_gates.size();i++) {
            gate_size = pow(2, mergings) - 1;
            overhead += pow(2, mergings) - 1;
        }
        cout << "UGs took " << overhead << " vertices." << endl;
        cout << "Total UC size is: " << total_uc_size << "\n";
    }
    vector<size_t> stats = {total_uc_size, vertices.size()};
    return make_pair(stats, universal_gates);
}

// Sets the universal gates such that the gates of the given DAG g are computed
void ValiantMerged::set_gates(DAG* g, unordered_map<int, int>& pole_mapping){
    for (DAG::Node* v: g->vertices){
        if (v->type == "input"){
            continue;
        } else if (v->type == "gate"){
            // Get the original order of inputs and its function table
            vector<int> input_order;
            for (DAG::Edge* e: v->in_edges){
                input_order.push_back(pole_mapping[e->from->number]);
            }

            // Get corresponding universal gate in the EUG
            ValiantMerged::Node* v_pole = poles[pole_mapping[v->number]-1];
            unordered_multiset<int> desired_inputs;
            for (int i : input_order) {
                desired_inputs.insert(i);
            }

            // Now get the order of inputs to this universal gate
            unordered_map<int, ValiantMerged::Edge*> gate_inputs;
            for(ValiantMerged::Edge* e_in: v_pole->in_edges){
                assert(e_in != 0);
                ValiantMerged::Node* u = v_pole->find_input(e_in);
                int input_nr = (u) ? u->number : -1; // If edge is not from a pole, mark by using -1
                gate_inputs[input_nr] = e_in;
            }
            unordered_multiset<ValiantMerged::Edge*> unused_edges;
            for (ValiantMerged::Edge* e : v_pole->in_edges) {
                unused_edges.insert(e);
            }

            // Make a new order for the incoming wires, first the desired wires
            vector<ValiantMerged::Edge*> new_in_edges;
            ValiantMerged::Edge* in_edge;
            for (int input: input_order){
                in_edge = gate_inputs[input];
                new_in_edges.push_back(in_edge);
                remove_single(unused_edges, in_edge);
            }
            // At this point the order of incoming wires is the same as in the graph to be embedded

            // Now handle the edges that carry unwanted inputs
            for (ValiantMerged::Edge* e: unused_edges){
                new_in_edges.push_back(e);
            }

            v_pole->in_edges = new_in_edges;
            gate_inputs.clear();

            vector<int> new_function_bits = set_function_bits(v->function_bits, v_pole->in_edges.size());
            v_pole->function_bits = new_function_bits;
        } else if (v->type == "output"){
            // Here we have to determine which wire we output
            assert(v->in_edges.size() == 1);
            int desired_output = pole_mapping[v->in_edges[0]->from->number];
            ValiantMerged::Node* v_pole = poles[pole_mapping[v->number]-1];
            unsigned int counter = 0;
            bool found = false;
            for (ValiantMerged::Edge* e_in : v_pole->in_edges){
                ValiantMerged::Node* input = v_pole->find_input(e_in);
                if (input && input->number == desired_output){
                    found = true;
                    break;
                }
                counter++;
            }
            assert(found); // The desired output is not mapped to this output node, there must be an error
            v_pole->control_bit = counter;
        }

    }
}

/*
Evaluates the SHDL file and the EUG with random inputs and compares if the results are equal.
This procedure (with new inputs) will be repeated according to the given iteration count.
If there is an iteration producing differnet results, false will be returned.
If each iteration produces the same results, true will be returned.
*/
bool ValiantMerged::check_circuit_correctness(string filename, int iterations) {
    srand(time(0));
    vector<bool> input_list;
    vector<bool> output_list;
    for (int i = 0; i < iterations; i++) {
        input_list.clear();
        output_list.clear();
        input_list = initialize_inputs(filename);
        eval_SHDL(filename, input_list, output_list);
        vector<bool> output_list2;
        eval_UC(input_list, output_list2);

        if (output_list2.size() == output_list.size()) {
            for (unsigned int i = 0; i < output_list.size(); i++) {
                if (output_list2[i] != output_list[i]) {
                    return false;
                }
            }
        }
        else {
            return false;
        }
    }
    return true;
}

ValiantMerged::Node::Node(int number, int eug_number, bool is_pole, string type, string identifier){
    this->number = number;
    this->eug_number = eug_number;
    this->is_pole = is_pole;
    this->type = type;
    this->identifier = identifier;
}

/*
Transforms a forwarding pole with less desired outputs than inputs into a "selection network" that selects which wires are passed through and which are cut off.
*/
void ValiantMerged::construct_hybrid_auxiliary_pole(ValiantMerged::Node* f_pole, ValiantMerged::Node* multi_input_pole, DAG* g){
    vector<int> wanted_inputs;
    for(DAG::Edge* e_in: g->vertices[f_pole->number - 1]->in_edges){
        wanted_inputs.push_back(e_in->from->number);
    }

    if (f_pole->num_inputs == 1 && f_pole->in_edges.size() == 2){
        // Replace this pole by a y switch
        // Find the wire that has the wanted input
        int wanted_input = g->vertices[f_pole->number - 1]->in_edges[0]->from->number;
        //cout << "Forward pole " << f_pole->number << " needs number " << wanted_input << endl;
        ValiantMerged::Node* input1 = f_pole->find_input(f_pole->in_edges[0]);
        ValiantMerged::Node* input2 = f_pole->find_input(f_pole->in_edges[1]);
        int correct_wire = -1;
        if (input1 && input1->number == wanted_input){
            correct_wire = 0;
        } else if (input2 && input2->number == wanted_input){
            correct_wire = 1;
        } else{
            cout << "none is correct" << endl;
            assert(false);
        }
        // Assign sides to the input wires
        f_pole->in_edges[0]->to_side = false; // assign right side
        f_pole->in_edges[1]->to_side = true; // assign left side

        f_pole->type = "y";
        f_pole->num_inputs = 2;
        f_pole->is_pole = false;
        f_pole->control_bit = correct_wire;
        clear_out_edges(f_pole);
        add_edge(f_pole, multi_input_pole, false, true);
        return;
    } else{
        vector<int> input_order;
        for(ValiantMerged::Edge* e_in: f_pole->in_edges){
            assert(e_in != 0);
            ValiantMerged::Node* u = f_pole->find_input(e_in);
            int input_nr = (u) ? u->number : -1; // If edge is not from a pole, mark by using -1
            input_order.push_back(input_nr);
        }


        if (f_pole->in_edges.size() == 3){
            vector<ValiantMerged::Node*> froms;
            vector<bool> from_sides;
            for (ValiantMerged::Edge* e_in: f_pole->in_edges){
                froms.push_back(e_in->from);
                from_sides.push_back(e_in->from_side);
            }
            clear_in_edges(f_pole);
            clear_out_edges(f_pole);
            if (f_pole->num_inputs == 1){ // 3-to-1-construction
                ValiantMerged::Node* y1_node;
                ValiantMerged::Node* y2_node;
                y1_node = new ValiantMerged::Node(-1,-1,false,"y","y1_" + f_pole->identifier);
                y2_node = new ValiantMerged::Node(-1,-1,false,"y", "y2_" + f_pole->identifier);
                this->vertices.push_back(y1_node);
                this->vertices.push_back(y2_node);

                add_edge(froms[0],y1_node,from_sides[0],true);
                add_edge(froms[1],y1_node,from_sides[1],false);
                add_edge(froms[2],y2_node,from_sides[2],false);
                add_edge(y1_node,y2_node,false, true);
                add_edge(y2_node, multi_input_pole, false, true);
                assert(wanted_inputs.size() == 1);
                int wanted_input = wanted_inputs[0];
                unsigned int index = 0;
                for (; index < input_order.size();index++){
                    int input = input_order[index];
                    if (input == wanted_input){
                        break;
                    }
                }
                if (index == 0){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                } else if (index == 1){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 1;
                } else if (index == 2){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                } else{
                    cerr << "Desired input not found!" << "\n";
                    assert(false);
                }
                return;

            }else if(f_pole->num_inputs == 2){ // 3-to-2-construction
                ValiantMerged::Node* y1_node;
                ValiantMerged::Node* y2_node;
                y1_node = new ValiantMerged::Node(-1,-1,false,"y","y1_" + f_pole->identifier);
                y2_node = new ValiantMerged::Node(-1,-1,false,"y", "y2_" + f_pole->identifier);
                this->vertices.push_back(y1_node);
                this->vertices.push_back(y2_node);

                add_edge(froms[0],y1_node,from_sides[0],true);
                add_edge(froms[1],y1_node,from_sides[1],false);
                add_edge(froms[1],y2_node,from_sides[1],true);
                add_edge(froms[2],y2_node,from_sides[2],false);
                add_edge(y1_node, multi_input_pole, false, true);
                add_edge(y2_node, multi_input_pole, false, true);
                assert(wanted_inputs.size() == 2);

                unordered_multiset<int> wanted_inputs_set;
                for (int i : wanted_inputs) {
                    wanted_inputs_set.insert(i);
                }
                // Find the entry which is undesired
                unsigned int index = 0;
                int undesired_index = -1;
                for (; index < input_order.size();index++){
                    int input = input_order[index];
                    if (wanted_inputs_set.find(input) == wanted_inputs_set.end()){
                        // Either this input is completely undesired or this input was already found and this here is a duplicate, so remove it
                        undesired_index = index;
                    } else{
                        // This input is found, remove one instance of it from the multiset
                        remove_single(wanted_inputs_set ,input);
                    }
                }
                assert(wanted_inputs_set.empty());
                if (undesired_index == 0){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                } else if (undesired_index == 1){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 0;
                } else if (undesired_index == 2){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                } else{
                    cerr << "Desired input not found!" << "\n";
                    assert(false);
                }
                return;
            }
        } else if (f_pole->in_edges.size() == 4){
            vector<ValiantMerged::Node*> froms;
            vector<bool> from_sides;
            for (ValiantMerged::Edge* e_in: f_pole->in_edges){
                froms.push_back(e_in->from);
                from_sides.push_back(e_in->from_side);
            }
            clear_in_edges(f_pole);
            clear_out_edges(f_pole);
            if (f_pole->num_inputs == 1){ // 4-to-1-construction
                ValiantMerged::Node* y1_node = new ValiantMerged::Node(-1,-1,false,"y","y1_" + f_pole->identifier);
                ValiantMerged::Node* y2_node = new ValiantMerged::Node(-1,-1,false,"y", "y2_" + f_pole->identifier);
                ValiantMerged::Node* y3_node = new ValiantMerged::Node(-1,-1,false,"y", "y3_" + f_pole->identifier);
                this->vertices.push_back(y1_node);
                this->vertices.push_back(y2_node);
                this->vertices.push_back(y3_node);

                add_edge(froms[0],y1_node,from_sides[0],true);
                add_edge(froms[1],y1_node,from_sides[1],false);
                add_edge(froms[2],y2_node,from_sides[2],false);
                add_edge(y1_node,y2_node,false, true);
                add_edge(froms[3],y3_node,from_sides[3],false);
                add_edge(y2_node,y3_node,false, true);
                add_edge(y3_node, multi_input_pole, false, true);
                assert(wanted_inputs.size() == 1);
                int wanted_input = wanted_inputs[0];
                unsigned int index = 0;
                for (; index < input_order.size();index++){
                    int input = input_order[index];
                    if (input == wanted_input){
                        break;
                    }
                }
                if (index == 0){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 1;
                } else if (index == 1){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 1;
                } else if (index == 2){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 1;
                } else if (index == 3){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                } else{
                    cerr << "Desired input not found!" << "\n";
                    assert(false);
                }
                return;
            } else if (f_pole->num_inputs == 2){ // 4-to-2-construction
                ValiantMerged::Node* y1_node = new ValiantMerged::Node(-1,-1,false,"y","y1_" + f_pole->identifier);
                ValiantMerged::Node* y2_node = new ValiantMerged::Node(-1,-1,false,"y", "y2_" + f_pole->identifier);
                ValiantMerged::Node* y3_node = new ValiantMerged::Node(-1,-1,false,"y", "y3_" + f_pole->identifier);
                ValiantMerged::Node* y4_node = new ValiantMerged::Node(-1,-1,false,"y", "y4_" + f_pole->identifier);
                ValiantMerged::Node* y5_node = new ValiantMerged::Node(-1,-1,false,"y", "y5_" + f_pole->identifier);
                this->vertices.push_back(y1_node);
                this->vertices.push_back(y2_node);
                this->vertices.push_back(y3_node);
                this->vertices.push_back(y4_node);
                this->vertices.push_back(y5_node);

                add_edge(froms[0],y1_node,from_sides[0],true);
                add_edge(froms[1],y1_node,from_sides[1],false);
                add_edge(froms[1],y2_node,from_sides[1],true);
                add_edge(froms[2],y2_node,from_sides[2],false);
                add_edge(froms[2],y3_node,from_sides[2],true);
                add_edge(froms[3],y3_node,from_sides[3],false);
                add_edge(y1_node,y4_node,false,true);
                add_edge(y2_node,y4_node,false,false);
                add_edge(y2_node,y5_node,false,true);
                add_edge(y3_node,y5_node,false,false);
                add_edge(y4_node, multi_input_pole, false, true);
                add_edge(y5_node, multi_input_pole, false, true);
                assert(wanted_inputs.size() == 2);


                // Find the desired entries
                unsigned int index = 0;
                int index1 = -1;
                int index2 = -1;
                for (; index < input_order.size();index++){
                    int input = input_order[index];
                    if (input == wanted_inputs[0] && index1 == -1){
                        index1 = index;
                    }else if (input == wanted_inputs[1] && index2 == -1){
                        index2 = index;
                    }
                }
                // Sort to easily check the following cases
                if (index1 > index2){
                    int tmp = index1;
                    index1 = index2;
                    index2 = tmp;
                }
                assert(index1 != index2);
                assert(index1 != -1 && index2 != -1);
                if (index1 == 0 && index2 == 1){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 1;
                    y5_node->control_bit = 1;
                } else if (index1 == 0 && index2 == 2){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 1;
                    y5_node->control_bit = 1;
                } else if (index1 == 0 && index2 == 3){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 1;
                    y5_node->control_bit = 0;
                } else if (index1 == 1 && index2 == 2){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 1;
                    y4_node->control_bit = 1;
                    y5_node->control_bit = 0;
                } else if (index1 == 1 && index2 == 3){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 1;
                    y5_node->control_bit = 0;
                } else if (index1 == 2 && index2 == 3){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                    y5_node->control_bit = 0;
                } else{
                    cerr << "Desired input not found!" << "\n";
                    assert(false);
                }
                return;
            } if (f_pole->num_inputs == 3){ // 4-to-3-construction
                ValiantMerged::Node* y1_node = new ValiantMerged::Node(-1,-1,false,"y","y1_" + f_pole->identifier);
                ValiantMerged::Node* y2_node = new ValiantMerged::Node(-1,-1,false,"y", "y2_" + f_pole->identifier);
                ValiantMerged::Node* y3_node = new ValiantMerged::Node(-1,-1,false,"y", "y3_" + f_pole->identifier);
                this->vertices.push_back(y1_node);
                this->vertices.push_back(y2_node);
                this->vertices.push_back(y3_node);

                add_edge(froms[0],y1_node,from_sides[0],true);
                add_edge(froms[1],y1_node,from_sides[1],false);
                add_edge(froms[1],y2_node,from_sides[1],true);
                add_edge(froms[2],y2_node,from_sides[2],false);
                add_edge(froms[2],y3_node,from_sides[2],true);
                add_edge(froms[3],y3_node,from_sides[3],false);
                add_edge(y1_node, multi_input_pole, false, true);
                add_edge(y2_node, multi_input_pole, false, true);
                add_edge(y3_node, multi_input_pole, false, true);
                assert(wanted_inputs.size() == 3);

                unordered_multiset<int> wanted_inputs_set;
                for (int i : wanted_inputs) {
                    wanted_inputs_set.insert(i);
                }
                // Find the entry which is undesired
                unsigned int index = 0;
                int undesired_index = -1;
                for (; index < input_order.size();index++){
                    int input = input_order[index];
                    if (wanted_inputs_set.find(input) == wanted_inputs_set.end()){
                        // Either this input is completely undesired or this input was already found and this here is a duplicate, so remove it
                        undesired_index = index;
                    } else{
                        // This input is found, remove one instance of it from the multiset
                        remove_single(wanted_inputs_set ,input);
                    }
                }
                assert(wanted_inputs_set.empty());

                if (undesired_index == 0){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                } else if (undesired_index == 1){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                } else if (undesired_index == 2){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 0;
                } else if (undesired_index == 3){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 1;
                } else{
                    cerr << "Desired input not found!" << "\n";
                    assert(false);
                }
                return;
            }
        } else if (f_pole->in_edges.size() == 5){
            vector<ValiantMerged::Node*> froms;
            vector<bool> from_sides;
            for (ValiantMerged::Edge* e_in: f_pole->in_edges){
                froms.push_back(e_in->from);
                from_sides.push_back(e_in->from_side);
            }
            clear_in_edges(f_pole);
            clear_out_edges(f_pole);
            if (f_pole->num_inputs == 1){ // 5-to-1-construction
                ValiantMerged::Node* y1_node = new ValiantMerged::Node(-1,-1,false,"y","y1_" + f_pole->identifier);
                ValiantMerged::Node* y2_node = new ValiantMerged::Node(-1,-1,false,"y", "y2_" + f_pole->identifier);
                ValiantMerged::Node* y3_node = new ValiantMerged::Node(-1,-1,false,"y", "y3_" + f_pole->identifier);
                ValiantMerged::Node* y4_node = new ValiantMerged::Node(-1,-1,false,"y", "y4_" + f_pole->identifier);
                this->vertices.push_back(y1_node);
                this->vertices.push_back(y2_node);
                this->vertices.push_back(y3_node);
                this->vertices.push_back(y4_node);

                add_edge(froms[0],y1_node,from_sides[0],true);
                add_edge(froms[1],y1_node,from_sides[1],false);
                add_edge(froms[2],y2_node,from_sides[2],false);
                add_edge(y1_node,y2_node,false, true);
                add_edge(froms[3],y3_node,from_sides[3],false);
                add_edge(y2_node,y3_node,false, true);
                add_edge(froms[4],y4_node,from_sides[4],false);
                add_edge(y3_node,y4_node,false, true);
                add_edge(y4_node, multi_input_pole, false, true);
                assert(wanted_inputs.size() == 1);
                int wanted_input = wanted_inputs[0];
                unsigned int index = 0;
                for (; index < input_order.size();index++){
                    int input = input_order[index];
                    if (input == wanted_input){
                        break;
                    }
                }
                if (index == 0){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 1;
                    y4_node->control_bit = 1;
                } else if (index == 1){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 1;
                    y4_node->control_bit = 1;
                } else if (index == 2){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 1;
                    y4_node->control_bit = 1;
                } else if (index == 3){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 1;
                } else if (index == 4){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                } else{
                    cerr << "Desired input not found!" << "\n";
                    assert(false);
                }
                return;
            } else if (f_pole->num_inputs == 2){ // 5-to-2-construction
                ValiantMerged::Node* y1_node = new ValiantMerged::Node(-1,-1,false,"y","y1_" + f_pole->identifier);
                ValiantMerged::Node* y2_node = new ValiantMerged::Node(-1,-1,false,"y", "y2_" + f_pole->identifier);
                ValiantMerged::Node* y3_node = new ValiantMerged::Node(-1,-1,false,"y", "y3_" + f_pole->identifier);
                ValiantMerged::Node* y4_node = new ValiantMerged::Node(-1,-1,false,"y", "y4_" + f_pole->identifier);
                ValiantMerged::Node* y5_node = new ValiantMerged::Node(-1,-1,false,"y", "y5_" + f_pole->identifier);
                ValiantMerged::Node* y6_node = new ValiantMerged::Node(-1,-1,false,"y","y6_" + f_pole->identifier);
                ValiantMerged::Node* y7_node = new ValiantMerged::Node(-1,-1,false,"y", "y7_" + f_pole->identifier);
                ValiantMerged::Node* y8_node = new ValiantMerged::Node(-1,-1,false,"y", "y8_" + f_pole->identifier);
                this->vertices.push_back(y1_node);
                this->vertices.push_back(y2_node);
                this->vertices.push_back(y3_node);
                this->vertices.push_back(y4_node);
                this->vertices.push_back(y5_node);
                this->vertices.push_back(y6_node);
                this->vertices.push_back(y7_node);
                this->vertices.push_back(y8_node);

                add_edge(froms[0],y1_node,from_sides[0],true);
                add_edge(froms[1],y1_node,from_sides[1],false);
                add_edge(froms[2],y2_node,from_sides[2],false);
                add_edge(y1_node,y2_node,false, true);
                add_edge(froms[3],y3_node,from_sides[3],false);
                add_edge(y2_node,y3_node,false, true);
                add_edge(froms[4],y4_node,from_sides[4],false);
                add_edge(y3_node,y4_node,false, true);
                add_edge(froms[0],y5_node,from_sides[0],true);
                add_edge(froms[1],y5_node,from_sides[1],false);
                add_edge(froms[2],y6_node,from_sides[2],false);
                add_edge(y5_node,y6_node,false, true);
                add_edge(froms[3],y7_node,from_sides[3],false);
                add_edge(y6_node,y7_node,false, true);
                add_edge(froms[4],y8_node,from_sides[4],false);
                add_edge(y7_node,y8_node,false, true);
                add_edge(y4_node, multi_input_pole, false, true);
                add_edge(y8_node, multi_input_pole, false, true);
                assert(wanted_inputs.size() == 2);


                // Find the desired entries
                unsigned int index = 0;
                int index1 = -1;
                int index2 = -1;
                for (; index < input_order.size();index++){
                    int input = input_order[index];
                    if (input == wanted_inputs[0] && index1 == -1){
                        index1 = index;
                    }else if (input == wanted_inputs[1] && index2 == -1){
                        index2 = index;
                    }
                }
                // Sort to easily check the following cases
                if (index1 > index2){
                    int tmp = index1;
                    index1 = index2;
                    index2 = tmp;
                }
                assert(index1 != index2);
                assert(index1 != -1 && index2 != -1);
                // The routings of index1 and index2 are independent of each other

                // Routing for index1
                if (index1 == 0){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 1;
                    y4_node->control_bit = 1;
                } else if (index1 == 1){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 1;
                    y4_node->control_bit = 1;
                } else if (index1 == 2){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 1;
                    y4_node->control_bit = 1;
                } else if (index1 == 3){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 1;
                } else if (index1 == 4){
                    cerr << "index1 can not be the largest possible index" << "\n";
                    assert(false);
                }

                // Routing for index 2
                if (index2 == 0){
                    cerr << "index2 can not be the smallest possible index" << "\n";
                    assert(false);
                } else if (index2 == 1){
                    y5_node->control_bit = 0;
                    y6_node->control_bit = 1;
                    y7_node->control_bit = 1;
                    y8_node->control_bit = 1;
                } else if (index2 == 2){
                    y5_node->control_bit = 0;
                    y6_node->control_bit = 0;
                    y7_node->control_bit = 1;
                    y8_node->control_bit = 1;
                } else if (index2 == 3){
                    y5_node->control_bit = 0;
                    y6_node->control_bit = 0;
                    y7_node->control_bit = 0;
                    y8_node->control_bit = 1;
                } else if (index2 == 4){
                    y5_node->control_bit = 0;
                    y6_node->control_bit = 0;
                    y7_node->control_bit = 0;
                    y8_node->control_bit = 0;
                }
                return;
            } else if (f_pole->num_inputs == 3){ // 5-to-3-construction
                ValiantMerged::Node* y1_node = new ValiantMerged::Node(-1,-1,false,"y","y1_" + f_pole->identifier);
                ValiantMerged::Node* y2_node = new ValiantMerged::Node(-1,-1,false,"y", "y2_" + f_pole->identifier);
                ValiantMerged::Node* y3_node = new ValiantMerged::Node(-1,-1,false,"y", "y3_" + f_pole->identifier);
                ValiantMerged::Node* y4_node = new ValiantMerged::Node(-1,-1,false,"y","y4_" + f_pole->identifier);
                ValiantMerged::Node* y5_node = new ValiantMerged::Node(-1,-1,false,"y", "y5_" + f_pole->identifier);
                ValiantMerged::Node* y6_node = new ValiantMerged::Node(-1,-1,false,"y", "y6_" + f_pole->identifier);
                ValiantMerged::Node* y7_node = new ValiantMerged::Node(-1,-1,false,"y", "y7_" + f_pole->identifier);
                this->vertices.push_back(y1_node);
                this->vertices.push_back(y2_node);
                this->vertices.push_back(y3_node);
                this->vertices.push_back(y4_node);
                this->vertices.push_back(y5_node);
                this->vertices.push_back(y6_node);
                this->vertices.push_back(y7_node);

                add_edge(froms[0],y1_node,from_sides[0],true);
                add_edge(froms[1],y1_node,from_sides[1],false);
                add_edge(froms[1],y2_node,from_sides[1],true);
                add_edge(froms[2],y2_node,from_sides[2],false);
                add_edge(froms[2],y3_node,from_sides[2],true);
                add_edge(froms[3],y3_node,from_sides[3],false);
                add_edge(froms[3],y4_node,from_sides[2],true);
                add_edge(froms[4],y4_node,from_sides[3],false);
                add_edge(y1_node,y5_node,false,true);
                add_edge(y2_node,y5_node,false,false);
                add_edge(y2_node, y6_node,false,true);
                add_edge(y3_node,y6_node,false,false);
                add_edge(y3_node, y7_node,false,true);
                add_edge(y4_node, y7_node,false,false);



                add_edge(y5_node, multi_input_pole, false, true);
                add_edge(y6_node, multi_input_pole, false, true);
                add_edge(y7_node, multi_input_pole, false, true);
                assert(wanted_inputs.size() == 3);

                unordered_multiset<int> wanted_inputs_set;
                for (int i : wanted_inputs) {
                    wanted_inputs_set.insert(i);
                }
                // Find the entry which is undesired
                unsigned int index = 0;
                int undesired_index1 = -1;
                int undesired_index2 = -1;
                for (; index < input_order.size();index++){
                    int input = input_order[index];
                    if (wanted_inputs_set.find(input) == wanted_inputs_set.end()){
                        // Either this input is completely undesired or this input was already found and this here is a duplicate, so remove it
                        if (undesired_index1 == -1){
                            // The first undesired input
                            undesired_index1 = index;
                        } else {
                            // First is already found, so set the second
                            undesired_index2 = index;
                        }
                    } else{
                        // This (correct) input is found, remove one instance of it from the multiset
                        remove_single(wanted_inputs_set ,input);
                    }
                }
                assert(wanted_inputs_set.empty());

                // Sort to easily check the following cases
                if (undesired_index1 > undesired_index2){
                    int tmp = undesired_index1;
                    undesired_index1 = undesired_index2;
                    undesired_index2 = tmp;
                }
                assert(undesired_index1 != undesired_index2);
                assert(undesired_index1 != -1 && undesired_index2 != -1);

                if (undesired_index1 == 0 && undesired_index2 == 1){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                    y5_node->control_bit = 0;
                    y6_node->control_bit = 0;
                    y7_node->control_bit = 0;
                } else if (undesired_index1 == 0 && undesired_index2 == 2){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                    y5_node->control_bit = 1;
                    y6_node->control_bit = 0;
                    y7_node->control_bit = 0;
                } else if (undesired_index1 == 0 && undesired_index2 == 3){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                    y5_node->control_bit = 1;
                    y6_node->control_bit = 1;
                    y7_node->control_bit = 0;
                } else if (undesired_index1 == 0 && undesired_index2 == 4){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                    y5_node->control_bit = 1;
                    y6_node->control_bit = 1;
                    y7_node->control_bit = 1;
                } else if (undesired_index1 == 1 && undesired_index2 == 2){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                    y5_node->control_bit = 1;
                    y6_node->control_bit = 0;
                    y7_node->control_bit = 0;
                } else if (undesired_index1 == 1 && undesired_index2 == 3){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                    y5_node->control_bit = 1;
                    y6_node->control_bit = 1;
                    y7_node->control_bit = 0;
                } else if (undesired_index1 == 1 && undesired_index2 == 4){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                    y5_node->control_bit = 1;
                    y6_node->control_bit = 1;
                    y7_node->control_bit = 1;
                } else if (undesired_index1 == 2 && undesired_index2 == 3){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                    y5_node->control_bit = 1;
                    y6_node->control_bit = 1;
                    y7_node->control_bit = 0;
                } else if (undesired_index1 == 2 && undesired_index2 == 4){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                    y5_node->control_bit = 1;
                    y6_node->control_bit = 1;
                    y7_node->control_bit = 1;
                } else if (undesired_index1 == 3 && undesired_index2 == 4){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 1;
                    y4_node->control_bit = 0;
                    y5_node->control_bit = 1;
                    y6_node->control_bit = 1;
                    y7_node->control_bit = 1;
                } else{
                    cerr << "case not found" << "\n";
                    assert(false);
                }
                return;
            } else if (f_pole->num_inputs == 4){ // 5-to-4-construction
                ValiantMerged::Node* y1_node = new ValiantMerged::Node(-1,-1,false,"y","y1_" + f_pole->identifier);
                ValiantMerged::Node* y2_node = new ValiantMerged::Node(-1,-1,false,"y", "y2_" + f_pole->identifier);
                ValiantMerged::Node* y3_node = new ValiantMerged::Node(-1,-1,false,"y", "y3_" + f_pole->identifier);
                ValiantMerged::Node* y4_node = new ValiantMerged::Node(-1,-1,false,"y", "y4_" + f_pole->identifier);
                this->vertices.push_back(y1_node);
                this->vertices.push_back(y2_node);
                this->vertices.push_back(y3_node);
                this->vertices.push_back(y4_node);

                add_edge(froms[0],y1_node,from_sides[0],true);
                add_edge(froms[1],y1_node,from_sides[1],false);
                add_edge(froms[1],y2_node,from_sides[1],true);
                add_edge(froms[2],y2_node,from_sides[2],false);
                add_edge(froms[2],y3_node,from_sides[2],true);
                add_edge(froms[3],y3_node,from_sides[3],false);
                add_edge(froms[3],y4_node,from_sides[3],true);
                add_edge(froms[4],y4_node,from_sides[4],false);
                add_edge(y1_node, multi_input_pole, false, true);
                add_edge(y2_node, multi_input_pole, false, true);
                add_edge(y3_node, multi_input_pole, false, true);
                add_edge(y4_node, multi_input_pole, false, true);
                assert(wanted_inputs.size() == 4);

                unordered_multiset<int> wanted_inputs_set;
                for (int i : wanted_inputs) {
                    wanted_inputs_set.insert(i);
                }
                // Find the entry which is undesired
                unsigned int index = 0;
                int undesired_index = -1;
                for (; index < input_order.size();index++){
                    int input = input_order[index];
                    if (wanted_inputs_set.find(input) == wanted_inputs_set.end()){
                        // Either this input is completely undesired or this input was already found and this here is a duplicate, so remove it
                        undesired_index = index;
                    } else{
                        // This input is found, remove one instance of it from the multiset
                        remove_single(wanted_inputs_set ,input);
                    }
                }
                assert(wanted_inputs_set.empty());

                if (undesired_index == 0){
                    y1_node->control_bit = 0;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                } else if (undesired_index == 1){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 0;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                } else if (undesired_index == 2){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 0;
                    y4_node->control_bit = 0;
                } else if (undesired_index == 3){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 1;
                    y4_node->control_bit = 0;
                } else if (undesired_index == 4){
                    y1_node->control_bit = 1;
                    y2_node->control_bit = 1;
                    y3_node->control_bit = 1;
                    y4_node->control_bit = 1;
                } else{
                    cerr << "Desired input not found!" << "\n";
                    assert(false);
                }
                return;
            }
        }
    }
}
