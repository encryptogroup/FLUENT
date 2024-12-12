#include <cstdint>
#include <string>
#include <iostream>
#include <cstring>
#include <unordered_map>
#include <sstream>
#include <algorithm>
#include <iterator>
#include <cassert>
#include <unistd.h>
#include <unordered_set>
#include <random>
#include <chrono>
#include <iostream>
#include <fstream>
#include <math.h>
#include <stdio.h>
#include <getopt.h>
#include <filesystem>
#include <chrono>


#include "uc/2way/valiant.h"
#include "uc/2way/liu.h"
#include "uc/2way/valiantMerged.h"
#include "util/parseBench.h"
#include "util/utility.h"


// Helper function that seperates a string into a vectopr seperated by a delimiter
void tokenize2(const string& str, vector<string>& tokens) {
	tokens.clear();
    char delimiter = '_';
	string::size_type last_pos = str.find_first_not_of(delimiter, 0);
	string::size_type pos = str.find_first_of(delimiter, last_pos);
	while (string::npos != pos || string::npos != last_pos) {
		tokens.push_back(str.substr(last_pos, pos - last_pos).c_str());
		last_pos = str.find_first_not_of(delimiter, pos);
		pos = str.find_first_of(delimiter, last_pos);
	}
}

// Helper function to parse the filepath
vector<string> parse_filename(string path){
    vector<string> tokens;
    tokenize2(path, tokens);
    return tokens;

}

// Saves basic properties of the UC into a given text file
void save_results(string result_filename, string circuit_filename, string algorithm, bool in_place, unsigned int fanout, pair<vector<size_t>,vector<unsigned long>> eug_stats, vector<unsigned int> dag_sizes, string circuit_name = "none", unsigned int circuit_lut_size = 0){
    ofstream os;
    os.open(result_filename, std::ios_base::app);
    os << circuit_name << "\t" << circuit_lut_size << "\t" << circuit_filename << "\t" << algorithm << "\t" << in_place << "\t" << fanout << "\t"
        << dag_sizes[0] << "\t" << dag_sizes[1] << "\t" << dag_sizes[2] << "\t" << eug_stats.first[0] << "\t" << eug_stats.first[1] << "\t";
    for(unsigned int i = 0; i < eug_stats.second.size(); i++){
        os << eug_stats.second[i];
        if (i != eug_stats.second.size()-1){
            os << ":";
        }
    }
    os << endl;
}


/*
Creates the UC and its programming bits for a given circuit
input_filename is the path to the circuit in Bench or SHDL format
algorithm decides which EUG/UC algorithm to use, options are liu and valiant
in_place = true uses dynamic / in-place multi-input gates, otherwise sufficiently many EUGs are merged to achieve this
fanout decides to which fanout the circuit is reduced
copies allows to use duplicate the input circuit if it is given in Bench format
correctness_check toggles the correctness check of the EUG and UC
input_circuit_name is the name displayed in the benchmarks.txt file
circuit_lut_size is the used LUT size for the circuit that is saved in benchmarks.txt
*/
ValiantMerged* create_UC(string input_filename, string algorithm, bool in_place, unsigned int fanout, int copies, bool correctness_check, string input_circuit_name = "none", unsigned int circuit_lut_size = 0) {
    // Parse input into DAG
    cout << "--- Parsing Inputs ---" << endl;
    string filename = input_filename;
    string tmp = input_filename.substr(input_filename.length() - 6, 6);
    string circuit_name = "";
    if (tmp == ".bench") {
        cout << "Convert .bench to SHDL" << endl;
        parse_bench(input_filename, copies);
        string tmp2 = input_filename.substr(0, input_filename.length() - 6);
        string circuit_name = tmp2.substr(8, tmp2.length() - 8);
        cout << "Circuit name: " << circuit_name << endl;
        filename = "circuits/" + circuit_name + "_SHDL";
    }
    using std::chrono::high_resolution_clock;
    using std::chrono::duration_cast;
    using std::chrono::duration;
    using std::chrono::milliseconds;

    auto t1 = high_resolution_clock::now();
    std::cout << "Given circuit file: " << filename << "\n";
    DAG* gx = read_SHDL_to_Gamma(filename);
    cout << "Circuit transformed to DAG" << endl;

    vector<unsigned int> dag_sizes;
    cout << "Original graph stats:" << endl;
    vector<unsigned int> dag_stats = gx->get_stats();
    dag_sizes.push_back(dag_stats[0] + dag_stats[1] + dag_stats[3]);
    unsigned int max_orig_indegree = dag_stats[3];
    unsigned int max_fanout = max_orig_indegree;
    if (fanout > 2 && fanout > max_orig_indegree){
        max_fanout = fanout;
    } else if (in_place && fanout > 2){
        max_fanout = fanout;
    } else if (in_place){
        max_fanout = 2;
    }
    cout << "Max fanout set to " << max_fanout << endl;


    //  Possibly reduce fanout of DAG
    cout << "--- Possibly reducing fanout ---" << endl;
    gx->reduce_fan_out2(max_fanout);
    cout << "Fanout reduced graph stats:" << endl;
    dag_stats = gx->get_stats();
    dag_sizes.push_back(dag_stats[0] + dag_stats[1] + dag_stats[3]);



    unordered_map<int, int> pole_mapping;
    unordered_map<int, vector<int>> forwarding_poles;
    DAG* gx_old;
    // Use dynamic multi input gates
    if (in_place) {
        cout << "--- Using in-place multi input gates ---" << endl;
        gx_old = gx;
        pair<DAG*, pair<unordered_map<int, int>, unordered_map<int, vector<int>>>> transform_info = gx->transform_in_place_graph(max_fanout);
        gx = transform_info.first;
        pole_mapping = transform_info.second.first;
        forwarding_poles = transform_info.second.second;
        cout << "In-place graph stats:" << endl;
        dag_stats = gx->get_stats();
    }
    dag_sizes.push_back(dag_stats[0] + dag_stats[1] + dag_stats[3]);


    uint32_t inputs = dag_stats[0];
    uint32_t gates = dag_stats[1];
    uint32_t outputs = dag_stats[2];



    // Split into Gamma1 graphs
    cout << "--- Splitting into Gamma1 graphs ---" << endl;
    vector<DAG*> dag1s = gx->split_into_gamma1(max_fanout);

    cout << "--- Creating Gamma1 EUGs ---" << endl;
    vector<ValiantBase*> eug1s;
    for (unsigned int i = 0; i < dag1s.size(); i++) {
        if (algorithm == "valiant") {
            eug1s.push_back(new Valiant2Way(inputs, gates, outputs, "(" + to_string(i) + ")", true));
        }
        else if (algorithm == "liu") {
            eug1s.push_back(new Liu2Way(inputs, gates, outputs, "(" + to_string(i) + ")", true));
        }
        else {
            cerr << "Construction algorithm unknown" << "\n";
            assert(false);
        }
    }

    cout << "--- Edge embedding Gamma1 graphs ---" << endl;
    int k = 0;
    for (ValiantBase* eug1 : eug1s) {
        eug1->edge_embed_gamma1(dag1s[k]);
        eug1->remove_x_switches();
        k++;
    }

    cout << "--- Merging " << eug1s.size() <<" Gamma1 EUGs ---" << endl;
    ValiantMerged* eug = new ValiantMerged(eug1s);


    eug->set_pole_information(gx);
    eug->transform_to_ABY_format();
    eug->remove_zero_degree_vertices();

    if (correctness_check){
        bool check11 = eug->check_correctness(gx);
        assert(check11);
        std::cout << "EUG correctness check passed!" << "\n";
    }

    pair<vector<size_t>,vector<unsigned long>> ret_pair;
    vector<size_t> eug_stats;
    vector<unsigned long> eug_ugs;
    ret_pair = eug->show_stats(max_fanout, in_place);
    eug_stats = ret_pair.first;
    eug_ugs = ret_pair.second;


    if (in_place) {
        cout << "--- Setting up multi input gates ---" << endl;
        eug->prepare_k_input(gx, gx_old, pole_mapping, forwarding_poles);
        eug->transform_to_ABY_format();
        eug->remove_zero_degree_vertices();
        ret_pair = eug->show_stats(max_fanout, in_place);
        eug_stats = ret_pair.first;
        eug_ugs = ret_pair.second;
        if (correctness_check){
            bool check111 = eug->check_correctness(gx_old, pole_mapping);
            assert(check111);
            std::cout << "Multi input gates correctness check passed!" << "\n";
        }
    }

    if (in_place){
        eug->set_gates(gx_old,pole_mapping);
    } else{
        // If there is no pole mapping, set the pole mapping to be the identidy
        if (pole_mapping.size() == 0){
            for(DAG::Node* v: gx->vertices){
                pair<int,int> tmp = make_pair(v->number,v->number);
                pole_mapping.insert(tmp);
            }
        }
        eug->set_gates(gx,pole_mapping);
    }

    eug->create_circuit_files();
    std::cout << "Circuit files created!" << endl;
    if (correctness_check){
        bool circuit_check = eug->check_circuit_correctness(filename, 1);
        assert(circuit_check);
        std::cout << "Universal Circuit correctness check passed!" << endl;
    }


    // Save the size properties etc. of the UC in benchmarks.txt
    save_results("benchmarks.txt", filename, algorithm, in_place, max_fanout, ret_pair, dag_sizes, input_circuit_name, circuit_lut_size);


    auto t2 = high_resolution_clock::now();
    auto secs = duration_cast<milliseconds>(t2-t1);

    std::cout << secs.count() << "ms\n";
    return 0;
}

// This function builds UCs for all .bench files in "/benches" without sub directories
void benchmark(){
    namespace fs = std::filesystem;
    string path = "benches/";
    vector<string> circuits;
    vector<string> params;
    vector<pair<string,unsigned int>> circuit_params;
    string circuit_name = "NO_NAME";
    unsigned int circuit_lut_size = 0;
    for (const auto & entry : fs::directory_iterator(path)){
        if (entry.path().extension() == ".bench"){
            cout << entry.path() << endl;
            circuits.push_back(entry.path().string());
            params = parse_filename(entry.path().filename().string());
            circuit_name = params[0];
            circuit_lut_size = stoi(params[1]);
            circuit_params.push_back(make_pair(circuit_name, circuit_lut_size));
        }
    }
    for(unsigned int i=0; i < circuits.size(); i++){
        create_UC(circuits[i], "liu", true,0,1, false, circuit_params[i].first, circuit_params[i].second);
    }
    for(unsigned int i=0; i < circuits.size(); i++){
        create_UC(circuits[i], "liu", false,0,1, false, circuit_params[i].first, circuit_params[i].second);
    }
}

int main(int argc, char* argv[]) {
    //shdl_to_bench("AES-expanded.txt_SHDL.circuit");
    //shdl_to_bench("md5.txt_SHDL.circuit");
    //return 0;
    string filename;
    string algorithm = "valiant";
    int copies = 1;
    bool inplace = false;
    unsigned int fanout = 0;
    bool correctness_check = true;

    static const struct option long_options[] =
    {
        { "file", required_argument,0, 'f' },
        { "liu", no_argument,       0, 'l' },
        { "inplace", no_argument, 0, 'i' },
        { "mergings", required_argument,       0, 0 },
        { "copies", required_argument,       0, 0 },
        { "no_check", no_argument,       0, 'n' },
        0
    };
    while (1) {
        int index = -1;
        struct option* opt = 0;
        int result = getopt_long(argc, argv,
            "f:li",
            long_options, &index);
        if (result == -1) break;
        switch (result) {
        case 'f':
            cout << "Given circuit file: " << optarg << "\n";
            filename = optarg;
            break;
        case 'l':
            cout << "Liu's construction will be used." << "\n";
            algorithm = "liu";
            break;
        case 'i':
            cout << "Inplace multi input gates enabled." << "\n";
            inplace = true;
            break;
        case 'n':
            cout << "Correctness checks disabled" << "\n";
            correctness_check = false;
            break;
        case 0:
            opt = (struct option*)&(long_options[index]);
            if (std::string(opt->name) == "mergings" && opt->has_arg == required_argument) {
                cout << "Maximum fanout of EUG set to " << optarg << ".\n";
                fanout = stoi(optarg);
            }
            else if (std::string(opt->name) == "copies" && opt->has_arg == required_argument) {
                cout << "Number of bench copies set to " << optarg << ".\n";
                copies = stoi(optarg);
            }
            break;
        default:
            break;
        }
    }
    while (optind < argc) {
        cout << "other parameter: " << argv[optind++] << "\n";
    }
    create_UC(filename, algorithm, inplace, fanout, copies, correctness_check);

    return 0;
}
