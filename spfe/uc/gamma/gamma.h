#ifndef GAMMA_H_INCLUDED
#define GAMMA_H_INCLUDED

#include <vector>
#include <unordered_map>
#include <math.h>
#include <cassert>
#include <queue>

#include "../util/utility.h"

using namespace std;

class DAG {
public:
    class Node;
    class Edge;
    class Node {
    public:
        int number;
        string type;
        vector<DAG::Edge*> in_edges;
        vector<DAG::Edge*> out_edges;
        vector<int> function_bits;
        string get_graphviz_style();
    };
    class Edge {
    public:
        DAG::Node* from;
        DAG::Node* to;
        Edge(DAG::Node* from, DAG::Node* to);
    };
    vector<DAG::Node*> vertices;
    void add_edge(DAG::Node* from, DAG::Node* to);
    DAG::Node* get_node(int nr);
    DAG* clone_DAG();
    DAG* create_bipartite();
    void print_graph(string name = "gamma");
    vector<vector<DAG::Edge*>> color_graph(int colors);
    void color_path(unordered_map<DAG::Edge*, int> &edge_colors, DAG::Edge* e, int alpha, int beta);
    vector<DAG*> split_into_gamma1(int nr_of_graphs = 2);
    DAG(int size);
    DAG();
    vector<unsigned int> get_stats();
    void reduce_fan_out(unsigned int max_outdegree);
    void reduce_fan_out2(unsigned int max_outdegree);
    void make_copy_gate_tree(unordered_map<DAG::Node*,vector<DAG::Node*>> &all_copy_gates, DAG::Node* v, unsigned int max_outdegree);
    void make_copy_gate_tree2(unordered_map<DAG::Node*,vector<DAG::Node*>> &all_copy_gates, DAG::Node* v, unsigned int max_outdegree);
    vector<DAG::Node*> add_copy_gate_tree(DAG::Node* v, unsigned int l, unsigned int max_outdegree);
    vector<DAG::Node*> add_copy_gate_tree_rec(DAG::Node* v, unsigned int l, unsigned int max_outdegree, unsigned int curr);
    pair<DAG*,pair<unordered_map<int, int>, unordered_map<int, vector<int>>>> transform_in_place_graph(unsigned int max_outdegree = 2);

};

DAG* read_SHDL_to_Gamma(string filename);

#endif // GAMMA_H_INCLUDED
