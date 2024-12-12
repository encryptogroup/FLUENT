
#ifndef VALIANTMERGED_H_INCLUDED
#define VALIANTMERGED_H_INCLUDED

#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <tuple>

#include "../../gamma/gamma.h"
#include "valiantBase.h"
#include "../../util/utility.h"


template <class T>
void remove_single(unordered_multiset<T>& uset, T elem);


class ValiantMerged {
public:
    struct Edge;
    struct Node;
    struct Node {
        int number;
        // The number of the eug in which this node was previously
        int eug_number;
        bool is_pole;
        bool is_k_input;
        int top_order;
        string position;
        vector<int> function_bits;
        unsigned int num_inputs;
        string type;
        int control_bit;
        string identifier;
        Node(int number, int eug_number, bool is_pole, string type, string identifier);
        Node(ValiantBase::Node* node, int eug_number);
        Node(ValiantMerged::Node* k_input_pole, string dis_range, string con_range);
        string get_identifier();
        string get_style();
        vector<ValiantMerged::Edge*> in_edges;
        vector<ValiantMerged::Edge*> out_edges;
        ValiantMerged::Node* find_input(ValiantMerged::Edge* e_in);
        vector<ValiantMerged::Node*> find_inputs();
        void topo_sort(unordered_set<ValiantMerged::Node*>& visited, list<ValiantMerged::Node*>& sorting);
        int convert_y_gate();
        ValiantMerged::Edge* get_in_edge(bool side);
        ValiantMerged::Edge* get_out_edge(bool side);
        void transform_y_switch();

    };

    struct Edge {
    public:
        ValiantMerged::Node* from;
        ValiantMerged::Node* to;
        bool from_side;
        bool to_side;

        Edge(ValiantMerged::Node* from, ValiantMerged::Node* to, bool from_side, bool to_side);
        void print_edge(ofstream& os);
        ValiantMerged::Edge* get_predecessor();
        ValiantMerged::Edge* find_input_rec();
    };

    vector<ValiantMerged::Node*> vertices;
    vector<ValiantMerged::Node*> poles;
    unordered_map<ValiantBase::Node*, ValiantMerged::Node*> node_mapping;
    list<ValiantMerged::Node*> topo_sorting;

    ValiantMerged(vector<ValiantBase*> gamma1_eugs);
    ValiantMerged();
    void print_graph_rec(ValiantMerged::Node* curr, unordered_set<ValiantMerged::Node*>& visited, ofstream& os);
    bool check_correctness(DAG* base_graph);
    bool check_correctness(DAG* base_graph, unordered_map<int, int>& pole_mapping);
    void add_edge(ValiantMerged::Node* from, ValiantMerged::Node* to, bool from_side, bool to_side);
    void remove_edge(ValiantMerged::Node* from, ValiantMerged::Node* to);
    tuple<vector<ValiantMerged::Edge*>::iterator, vector<ValiantMerged::Edge*>::iterator> remove_edge(ValiantMerged::Edge* e);
    void convert_edge(ValiantBase::Node* from, ValiantBase::Node* to, bool from_side, bool to_side, int eug_number);
    ValiantMerged::Node* get_corresponding_vertex(ValiantBase::Node* vertex, int eug_number);
    void merge_graph(ValiantBase* gamma1_eug, int eug_number);
    void merge_graph_rec(ValiantBase* gamma1_eug, ValiantBase::Node* curr, unordered_set<ValiantBase::Node*>& visited, int eug_number);
    void print_vertices(ofstream& os);
    void print_graph();
    void remove_copy_gates();
    void set_random_control_bits();
    void topo_sort();
    void create_circuit_files();
    void remove_input_edges();
    bool check_circuit_correctness(string filename, int iterations);
    void transform_y_switches();
    void transform_to_ABY_format();
    void remove_zero_degree_vertices();
    void prepare_k_input(DAG* g, DAG* g_old, unordered_map<int, int>& pole_mapping, unordered_map<int, vector<int>>& forwarding_poles);
    void clear_in_edges(ValiantMerged::Node* vertex);
    void clear_out_edges(ValiantMerged::Node* vertex);
    void optimize_x_switches();
    pair<vector<size_t>,vector<unsigned long>>  show_stats(unsigned int mergings, bool in_place = true);
    void set_pole_information(DAG* g);
    void set_pole_information(DAG* g, unordered_map<int, int>& pole_mapping);
    void set_gates(DAG* g, unordered_map<int, int>& pole_mapping);
    void set_gates(DAG* g);
    void construct_hybrid_auxiliary_pole(ValiantMerged::Node* f_pole, ValiantMerged::Node* multi_input_pole, DAG* g);
};

#endif // VALIANTMERGED_H_INCLUDED
