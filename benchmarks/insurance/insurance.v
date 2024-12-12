`define FIXEDPOINT_BITS 32
`define FIXEDPOINT_INTEGER_BITS 16
`define FIXEDPOINT_FRACTION_BITS (`FIXEDPOINT_BITS - `FIXEDPOINT_INTEGER_BITS)

`include "fixedpt_mul.v"
`include "fixedpt_div.v"
`include "fixedpt_pow.v"

module main
  (
 input wire [7:0]   hsn,
 input wire [15:0]  tsn,
 input wire [7:0]   firstlic,
 input wire [7:0]   takerlic,
 input wire [7:0]   age,
 input wire [7:0]   policyholder,
 input wire [7:0]   driving_license,
 input wire [7:0]   job,
 input wire [7:0]   drivers_under_25,
 input wire [31:0]  dmg1,
 input wire [31:0]  dmg2,
 input wire [7:0]   location_input,
 input wire [7:0]   points,
 input wire [7:0]   parkingspace,
 input wire [7:0]   carusage,
 input wire [7:0]   month,
 input wire [15:0]  annualdrivingdist,
 input wire [7:0]   damagefreeclasshp,
 input wire [7:0]   damagefreeclassvk,
 input wire [15:0]  paket,
 input wire [7:0]   selfpart,
 input wire [7:0]   workshop,
 input wire [7:0]   marder,
 input wire [7:0]   payment,
 input wire [7:0]   clubmember,
 input wire [7:0]   publictransport,
 input wire [7:0]   access,
 input wire [7:0]   protlet,
 input wire [7:0]   age_threshold,
 input wire [7:0]   workshopthres,
 input wire [7:0]   yearsthres,
 input wire [31:0]  liabilitycosts,
 input wire [31:0]  partialcoveredcosts,
 input wire [31:0]  fullycomprehensivecosts,
 input wire [31:0]  workshopcosts,
 output wire [31:0] result
);
   main2 tmp_main2({
 hsn,
 tsn,
 firstlic,
 takerlic,
 age,
 policyholder,
 driving_license,
 job,
 drivers_under_25,
 dmg1,
 dmg2,
 location_input,
 points,
 parkingspace,
 carusage,
 month,
 annualdrivingdist,
 damagefreeclasshp,
 damagefreeclassvk,
 paket,
 selfpart,
 workshop,
 marder,
 payment,
 clubmember,
 publictransport,
 access,
 protlet,
 age_threshold,
 workshopthres,
 yearsthres,
 liabilitycosts,
 partialcoveredcosts,
 fullycomprehensivecosts,
 workshopcosts
                    }, {result});
endmodule // main

module main2
(
 input wire [447:0] _input,
 output wire [31:0] _output
  );
   wire [7:0]       hsn;
   wire [15:0]      tsn;
   wire [7:0]       firstlic;
   wire [7:0]       takerlic;
   wire [7:0]       age;
   wire [7:0]       policyholder;
   wire [7:0]       driving_license;
   wire [7:0]       job;
   wire [7:0]       drivers_under_25;
   wire [31:0]      dmg1;
   wire [31:0]      dmg2;
   wire [7:0]       location_input;
   wire [7:0]       points;
   wire [7:0]       parkingspace;
   wire [7:0]       carusage;
   wire [7:0]       month;
   wire [15:0]      annualdrivingdist;
   wire [7:0]       damagefreeclasshp;
   wire [7:0]       damagefreeclassvk;
   wire [15:0]      paket;
   wire [7:0]       selfpart;
   wire [7:0]       workshop;
   wire [7:0]       marder;
   wire [7:0]       payment;
   wire [7:0]       clubmember;
   wire [7:0]       publictransport;
   wire [7:0]       access;
   wire [7:0]       protlet;
   wire [7:0]       age_threshold;
   wire [7:0]       workshopthres;
   wire [7:0]       yearsthres;
   wire [31:0]      liabilitycosts;
   wire [31:0]      partialcoveredcosts;
   wire [31:0]      fullycomprehensivecosts;
   wire [31:0]      workshopcosts;
   wire [31:0]      result;
   assign hsn = _input[7:0];
   assign tsn = _input[23:8];
   assign firstlic = _input[31:24];
   assign takerlic = _input[39:32];
   assign age = _input[47:40];
   assign policyholder = _input[55:48];
   assign driving_license = _input[63:56];
   assign job = _input[71:64];
   assign drivers_under_25 = _input[79:72];
   assign dmg1 = _input[111:80];
   assign dmg2 = _input[143:112];
   assign location_input = _input[151:144];
   assign points = _input[159:152];
   assign parkingspace = _input[167:160];
   assign carusage = _input[175:168];
   assign month = _input[183:176];
   assign annualdrivingdist = _input[199:184];
   assign damagefreeclasshp = _input[207:200];
   assign damagefreeclassvk = _input[215:208];
   assign paket = _input[231:216];
   assign selfpart = _input[239:232];
   assign workshop = _input[247:240];
   assign marder = _input[255:248];
   assign payment = _input[263:256];
   assign clubmember = _input[271:264];
   assign publictransport = _input[279:272];
   assign access = _input[287:280];
   assign protlet = _input[295:288];
   assign age_threshold = _input[303:296];
   assign workshopthres = _input[311:304];
   assign yearsthres = _input[319:312];
   assign liabilitycosts = _input[351:320];
   assign partialcoveredcosts = _input[383:352];
   assign fullycomprehensivecosts = _input[415:384];
   assign workshopcosts = _input[447:416];
   assign _output[31:0] = result;

   wire [7:0]       categorize_car_price;
   wire [7:0]       categorize_car_catcar;
   wire [7:0]       age_result;
   wire [15:0]      driver_result;
   wire [31:0]      damage_result;
   wire [7:0]       location_result;
   wire [31:0]      flensburg_result;
   wire [7:0]       car_usage_result;
   wire [31:0]      calculate_basic_price_result;
   wire [31:0]      saison_result;
   wire [31:0]      annual_drive_result;
   wire [31:0]      driver_person_pricehp;
   wire [31:0]      driver_person_pricetk;
   wire [31:0]      driver_person_pricevk;
   wire [31:0]      insurance_scope_result;
   wire [31:0]      extras_result;
   wire [31:0]      discount_result;
   wire [31:0]      protletter_result;

   categorize_car tmp_0({hsn, tsn, firstlic, takerlic}, {categorize_car_price, categorize_car_catcar});
   age tmp_1(age, age_threshold, age_result);
   driver tmp_2({age_result, policyholder, drivers_under_25, driving_license, job}, {driver_result});
   damage tmp_3(dmg1, dmg2, workshopthres, liabilitycosts, partialcoveredcosts, fullycomprehensivecosts, workshopcosts, damage_result);
   location tmp_4(location_input, location_result);
   flensburg tmp_5(points, flensburg_result);
   car_usage tmp_6({parkingspace, carusage}, {car_usage_result});
   calculate_basic_price tmp_7(categorize_car_price, location_result, driver_result, car_usage_result, damage_result, flensburg_result, calculate_basic_price_result);
   saison tmp_8(month, calculate_basic_price_result, saison_result);
   annual_drive tmp_9({annualdrivingdist, saison_result}, {annual_drive_result});
   driver_person tmp_10(damagefreeclasshp, damagefreeclassvk, annual_drive_result, driver_person_pricehp, driver_person_pricetk, driver_person_pricevk);
   insurance_scope tmp_11(driver_person_pricehp, driver_person_pricetk, driver_person_pricevk, selfpart, paket, insurance_scope_result);
   extras tmp_12(insurance_scope_result, workshop, marder, categorize_car_catcar, extras_result);
   discount tmp_13(insurance_scope_result, payment, clubmember, publictransport, access, discount_result);
   protletter tmp_14(insurance_scope_result, extras_result, discount_result, protlet, protletter_result);

   assign result = protletter_result;
endmodule // main

(* private *)
module categorize_car
(
 input wire [39:0] _inputs,
 output wire [15:0] _outputs
);
   wire [7:0]       hsn;
   wire [15:0]      tsn;
   wire [7:0]       firstlic;
   wire [7:0]       takerlic;
   wire [7:0]       price;
   wire [7:0]       catcar;
   assign hsn = _inputs[7:0];
   assign tsn = _inputs[23:8];
   assign firstlic = _inputs[31:24];
   assign takerlic = _inputs[39:32];
   assign _outputs[7:0] = price;
   assign _outputs[15:8] = catcar;

   wire [15:0]     price_0;
   wire [15:0]     price_1;
   wire [15:0]     price_2;
   wire [7:0]      catcar_0;
   wire [7:0]      firstlic_0;

   `define PETROL 12
   `define DIESEL 10
   `define GAS 8
   `define ELECTRO 16
   `define HYBRID 14

   assign price_0 = (hsn == 0 && tsn == 111) ? 50 + `PETROL + 28 :
                    (hsn == 0 && tsn == 112) ? 50 + `PETROL + 28 :
                    (hsn == 0 && tsn == 113) ? 50 + `PETROL + 30 :
                    (hsn == 0 && tsn == 114) ? 50 + `PETROL + 36 :
                    (hsn == 0 && tsn == 121) ? 50 + `DIESEL + 28 :
                    (hsn == 0 && tsn == 122) ? 50 + `DIESEL + 30 :
                    (hsn == 0 && tsn == 131) ? 50 + `ELECTRO + 30 :
                    (hsn == 0 && tsn == 211) ? 50 + `PETROL + 26 :
                    (hsn == 0 && tsn == 221) ? 50 + `ELECTRO + 26 :
                    (hsn == 0 && tsn == 231) ? 50 + `HYBRID + 26 :
                    (hsn == 0 && tsn == 232) ? 50 + `HYBRID + 28 :
                    (hsn == 0 && tsn == 311) ? 50 + `PETROL + 34 :
                    (hsn == 0 && tsn == 312) ? 50 + `PETROL + 38 :
                    (hsn == 0 && tsn == 313) ? 50 + `PETROL + 40 :
                    (hsn == 0 && tsn == 314) ? 50 + `PETROL + 54 :
                    (hsn == 0 && tsn == 321) ? 50 + `DIESEL + 32 :
                    (hsn == 0 && tsn == 322) ? 50 + `DIESEL + 38 :
                    (hsn == 0 && tsn == 323) ? 50 + `DIESEL + 42 :
                    (hsn == 0 && tsn == 324) ? 50 + `DIESEL + 28 :
                    (hsn == 0 && tsn == 331) ? 50 + `GAS + 34 :
                    (hsn == 0 && tsn == 332) ? 50 + `GAS + 42 :
                    (hsn == 0 && tsn == 411) ? 50 + `PETROL + 32 :
                    (hsn == 0 && tsn == 412) ? 50 + `PETROL + 34 :
                    (hsn == 0 && tsn == 413) ? 50 + `PETROL + 38 :
                    (hsn == 0 && tsn == 414) ? 50 + `PETROL + 40 :
                    (hsn == 0 && tsn == 421) ? 50 + `DIESEL + 32 :
                    (hsn == 0 && tsn == 422) ? 50 + `DIESEL + 34 :
                    (hsn == 0 && tsn == 423) ? 50 + `DIESEL + 34 :
                    (hsn == 0 && tsn == 424) ? 50 + `DIESEL + 38 :
                    (hsn == 0 && tsn == 431) ? 50 + `GAS + 34 :
                    (hsn == 0 && tsn == 432) ? 50 + `GAS + 36 :

                    (hsn == 1 && tsn == 111) ? 100 + `PETROL + 30 :
                    (hsn == 1 && tsn == 112) ? 100 + `PETROL + 32 :
                    (hsn == 1 && tsn == 113) ? 100 + `PETROL + 36 :
                    (hsn == 1 && tsn == 114) ? 100 + `PETROL + 36 :
                    (hsn == 1 && tsn == 121) ? 100 + `DIESEL + 30 :
                    (hsn == 1 && tsn == 122) ? 100 + `DIESEL + 32 :
                    (hsn == 1 && tsn == 123) ? 100 + `DIESEL + 34 :
                    (hsn == 1 && tsn == 211) ? 100 + `PETROL + 38 :
                    (hsn == 1 && tsn == 212) ? 100 + `PETROL + 44 :
                    (hsn == 1 && tsn == 213) ? 100 + `PETROL + 46 :
                    (hsn == 1 && tsn == 214) ? 100 + `PETROL + 52 :
                    (hsn == 1 && tsn == 221) ? 100 + `DIESEL + 40 :
                    (hsn == 1 && tsn == 311) ? 100 + `PETROL + 46 :
                    (hsn == 1 && tsn == 312) ? 100 + `PETROL + 46 :
                    (hsn == 1 && tsn == 313) ? 100 + `PETROL + 46 :
                    (hsn == 1 && tsn == 314) ? 100 + `PETROL + 56 :
                    (hsn == 1 && tsn == 321) ? 100 + `DIESEL + 34 :
                    (hsn == 1 && tsn == 322) ? 100 + `DIESEL + 36 :
                    (hsn == 1 && tsn == 323) ? 100 + `DIESEL + 40 :
                    (hsn == 1 && tsn == 324) ? 100 + `DIESEL + 46 :
                    (hsn == 1 && tsn == 331) ? 100 + `ELECTRO + 46 :
                    (hsn == 1 && tsn == 341) ? 100 + `HYBRID + 46 :
                    (hsn == 1 && tsn == 411) ? 100 + `PETROL + 46 :
                    (hsn == 1 && tsn == 412) ? 100 + `PETROL + 54 :
                    (hsn == 1 && tsn == 413) ? 100 + `PETROL + 70 :
                    (hsn == 1 && tsn == 414) ? 100 + `PETROL + 82 :
                    (hsn == 1 && tsn == 421) ? 100 + `DIESEL + 42 :
                    (hsn == 1 && tsn == 422) ? 100 + `DIESEL + 50 :
                    (hsn == 1 && tsn == 431) ? 100 + `ELECTRO + 50 :
                    (hsn == 1 && tsn == 432) ? 100 + `ELECTRO + 54 :
                    (hsn == 1 && tsn == 441) ? 100 + `HYBRID + 34 :
                    (hsn == 1 && tsn == 442) ? 100 + `HYBRID + 38 :

                    (hsn == 2 && tsn == 111) ? 250 + `PETROL + 32 :
                    (hsn == 2 && tsn == 112) ? 250 + `PETROL + 34 :
                    (hsn == 2 && tsn == 113) ? 250 + `PETROL + 40 :
                    (hsn == 2 && tsn == 114) ? 250 + `PETROL + 44 :
                    (hsn == 2 && tsn == 121) ? 250 + `DIESEL + 30 :
                    (hsn == 2 && tsn == 122) ? 250 + `DIESEL + 32 :
                    (hsn == 2 && tsn == 123) ? 250 + `DIESEL + 34 :
                    (hsn == 2 && tsn == 124) ? 250 + `DIESEL + 38 :
                    (hsn == 2 && tsn == 131) ? 250 + `ELECTRO + 28 :
                    (hsn == 2 && tsn == 211) ? 250 + `PETROL + 36 :
                    (hsn == 2 && tsn == 212) ? 250 + `PETROL + 40 :
                    (hsn == 2 && tsn == 213) ? 250 + `PETROL + 42 :
                    (hsn == 2 && tsn == 214) ? 250 + `PETROL + 50 :
                    (hsn == 2 && tsn == 221) ? 250 + `DIESEL + 36 :
                    (hsn == 2 && tsn == 222) ? 250 + `DIESEL + 36 :
                    (hsn == 2 && tsn == 223) ? 250 + `DIESEL + 42 :
                    (hsn == 2 && tsn == 224) ? 250 + `DIESEL + 48 :
                    (hsn == 2 && tsn == 231) ? 250 + `ELECTRO + 40 :
                    (hsn == 2 && tsn == 232) ? 250 + `ELECTRO + 42 :
                    (hsn == 2 && tsn == 233) ? 250 + `ELECTRO + 50 :
                    (hsn == 2 && tsn == 234) ? 250 + `ELECTRO + 64 :
                    (hsn == 2 && tsn == 241) ? 250 + `HYBRID + 40 :
                    (hsn == 2 && tsn == 242) ? 250 + `HYBRID + 42 :
                    (hsn == 2 && tsn == 243) ? 250 + `HYBRID + 50 :
                    (hsn == 2 && tsn == 244) ? 250 + `HYBRID + 64 :
                    (hsn == 2 && tsn == 311) ? 250 + `PETROL + 50 :
                    (hsn == 2 && tsn == 312) ? 250 + `PETROL + 54 :
                    (hsn == 2 && tsn == 313) ? 250 + `PETROL + 58 :
                    (hsn == 2 && tsn == 314) ? 250 + `PETROL + 64 :
                    (hsn == 2 && tsn == 321) ? 250 + `DIESEL + 38 :
                    (hsn == 2 && tsn == 322) ? 250 + `DIESEL + 46 :
                    (hsn == 2 && tsn == 323) ? 250 + `DIESEL + 50 :
                    (hsn == 2 && tsn == 324) ? 250 + `DIESEL + 54 :
                    (hsn == 2 && tsn == 331) ? 250 + `ELECTRO + 50 :
                    (hsn == 2 && tsn == 332) ? 250 + `ELECTRO + 58 :
                    (hsn == 2 && tsn == 333) ? 250 + `ELECTRO + 64 :
                    (hsn == 2 && tsn == 341) ? 250 + `HYBRID + 50 :
                    (hsn == 2 && tsn == 342) ? 250 + `HYBRID + 58 :
                    (hsn == 2 && tsn == 343) ? 250 + `HYBRID + 64 :
                    (hsn == 2 && tsn == 411) ? 250 + `PETROL + 48 :
                    (hsn == 2 && tsn == 412) ? 250 + `PETROL + 64 :
                    (hsn == 2 && tsn == 413) ? 250 + `PETROL + 74 :
                    (hsn == 2 && tsn == 414) ? 250 + `PETROL + 84 :
                    (hsn == 2 && tsn == 421) ? 250 + `DIESEL + 46 :
                    (hsn == 2 && tsn == 422) ? 250 + `DIESEL + 50 :
                    (hsn == 2 && tsn == 423) ? 250 + `DIESEL + 54 :
                    (hsn == 2 && tsn == 431) ? 250 + `ELECTRO + 58 :
                    (hsn == 2 && tsn == 432) ? 250 + `ELECTRO + 64 :
                    (hsn == 2 && tsn == 441) ? 250 + `HYBRID + 58 :
                    (hsn == 2 && tsn == 442) ? 250 + `HYBRID + 64 :

                    (hsn == 3 && tsn == 111) ? 150 + `PETROL + 40 :
                    (hsn == 3 && tsn == 112) ? 150 + `PETROL + 46 :
                    (hsn == 3 && tsn == 113) ? 150 + `PETROL + 50 :
                    (hsn == 3 && tsn == 121) ? 150 + `DIESEL + 36 :
                    (hsn == 3 && tsn == 122) ? 150 + `DIESEL + 38 :
                    (hsn == 3 && tsn == 123) ? 150 + `DIESEL + 46 :
                    (hsn == 3 && tsn == 211) ? 150 + `PETROL + 50 :
                    (hsn == 3 && tsn == 212) ? 150 + `PETROL + 60 :
                    (hsn == 3 && tsn == 213) ? 150 + `PETROL + 76 :
                    (hsn == 3 && tsn == 214) ? 150 + `PETROL + 78 :
                    (hsn == 3 && tsn == 311) ? 150 + `ELECTRO + 44 :
                    (hsn == 3 && tsn == 411) ? 150 + `PETROL + 46 :
                    (hsn == 3 && tsn == 412) ? 150 + `PETROL + 60 :
                    (hsn == 3 && tsn == 413) ? 150 + `PETROL + 68 :
                    (hsn == 3 && tsn == 414) ? 150 + `PETROL + 78 :
                    (hsn == 3 && tsn == 421) ? 150 + `DIESEL + 50 :

                    0;
   assign catcar_0 = (hsn == 0 && tsn == 111) ? 1 :
                     (hsn == 0 && tsn == 112) ? 1 :
                     (hsn == 0 && tsn == 113) ? 1 :
                     (hsn == 0 && tsn == 114) ? 2 :
                     (hsn == 0 && tsn == 121) ? 1 :
                     (hsn == 0 && tsn == 122) ? 1 :
                     (hsn == 0 && tsn == 131) ? 1 :
                     (hsn == 0 && tsn == 211) ? 1 :
                     (hsn == 0 && tsn == 221) ? 1 :
                     (hsn == 0 && tsn == 231) ? 1 :
                     (hsn == 0 && tsn == 232) ? 1 :
                     (hsn == 0 && tsn == 311) ? 2 :
                     (hsn == 0 && tsn == 312) ? 3 :
                     (hsn == 0 && tsn == 313) ? 3 :
                     (hsn == 0 && tsn == 314) ? 6 :
                     (hsn == 0 && tsn == 321) ? 2 :
                     (hsn == 0 && tsn == 322) ? 2 :
                     (hsn == 0 && tsn == 323) ? 3 :
                     (hsn == 0 && tsn == 324) ? 4 :
                     (hsn == 0 && tsn == 331) ? 2 :
                     (hsn == 0 && tsn == 332) ? 4 :
                     (hsn == 0 && tsn == 411) ? 2 :
                     (hsn == 0 && tsn == 412) ? 2 :
                     (hsn == 0 && tsn == 413) ? 3 :
                     (hsn == 0 && tsn == 414) ? 3 :
                     (hsn == 0 && tsn == 421) ? 2 :
                     (hsn == 0 && tsn == 422) ? 2 :
                     (hsn == 0 && tsn == 423) ? 2 :
                     (hsn == 0 && tsn == 424) ? 3 :
                     (hsn == 0 && tsn == 431) ? 2 :
                     (hsn == 0 && tsn == 432) ? 2 :

                     (hsn == 1 && tsn == 111) ? 1 :
                     (hsn == 1 && tsn == 112) ? 2 :
                     (hsn == 1 && tsn == 113) ? 2 :
                     (hsn == 1 && tsn == 114) ? 3 :
                     (hsn == 1 && tsn == 121) ? 1 :
                     (hsn == 1 && tsn == 122) ? 2 :
                     (hsn == 1 && tsn == 123) ? 2 :
                     (hsn == 1 && tsn == 211) ? 3 :
                     (hsn == 1 && tsn == 212) ? 4 :
                     (hsn == 1 && tsn == 213) ? 4 :
                     (hsn == 1 && tsn == 214) ? 6 :
                     (hsn == 1 && tsn == 221) ? 3 :
                     (hsn == 1 && tsn == 311) ? 4 :
                     (hsn == 1 && tsn == 312) ? 4 :
                     (hsn == 1 && tsn == 313) ? 5 :
                     (hsn == 1 && tsn == 314) ? 7 :
                     (hsn == 1 && tsn == 321) ? 2 :
                     (hsn == 1 && tsn == 322) ? 2 :
                     (hsn == 1 && tsn == 323) ? 3 :
                     (hsn == 1 && tsn == 324) ? 4 :
                     (hsn == 1 && tsn == 331) ? 4 :
                     (hsn == 1 && tsn == 341) ? 4 :
                     (hsn == 1 && tsn == 411) ? 5 :
                     (hsn == 1 && tsn == 412) ? 6 :
                     (hsn == 1 && tsn == 413) ? 9 :
                     (hsn == 1 && tsn == 414) ? 10 :
                     (hsn == 1 && tsn == 421) ? 4 :
                     (hsn == 1 && tsn == 422) ? 5 :
                     (hsn == 1 && tsn == 431) ? 5 :
                     (hsn == 1 && tsn == 432) ? 6 :
                     (hsn == 1 && tsn == 441) ? 5 :
                     (hsn == 1 && tsn == 442) ? 6 :

                     (hsn == 2 && tsn == 111) ? 2 :
                     (hsn == 2 && tsn == 112) ? 2 :
                     (hsn == 2 && tsn == 113) ? 3 :
                     (hsn == 2 && tsn == 114) ? 4 :
                     (hsn == 2 && tsn == 121) ? 1 :
                     (hsn == 2 && tsn == 122) ? 2 :
                     (hsn == 2 && tsn == 123) ? 2 :
                     (hsn == 2 && tsn == 124) ? 3 :
                     (hsn == 2 && tsn == 131) ? 1 :
                     (hsn == 2 && tsn == 211) ? 3 :
                     (hsn == 2 && tsn == 212) ? 3 :
                     (hsn == 2 && tsn == 213) ? 4 :
                     (hsn == 2 && tsn == 214) ? 5 :
                     (hsn == 2 && tsn == 221) ? 2 :
                     (hsn == 2 && tsn == 222) ? 3 :
                     (hsn == 2 && tsn == 223) ? 4 :
                     (hsn == 2 && tsn == 224) ? 5 :
                     (hsn == 2 && tsn == 231) ? 3 :
                     (hsn == 2 && tsn == 232) ? 4 :
                     (hsn == 2 && tsn == 233) ? 5 :
                     (hsn == 2 && tsn == 234) ? 8 :
                     (hsn == 2 && tsn == 241) ? 3 :
                     (hsn == 2 && tsn == 242) ? 4 :
                     (hsn == 2 && tsn == 243) ? 5 :
                     (hsn == 2 && tsn == 244) ? 8 :
                     (hsn == 2 && tsn == 311) ? 5 :
                     (hsn == 2 && tsn == 312) ? 6 :
                     (hsn == 2 && tsn == 313) ? 7 :
                     (hsn == 2 && tsn == 314) ? 8 :
                     (hsn == 2 && tsn == 321) ? 3 :
                     (hsn == 2 && tsn == 322) ? 4 :
                     (hsn == 2 && tsn == 323) ? 5 :
                     (hsn == 2 && tsn == 324) ? 6 :
                     (hsn == 2 && tsn == 331) ? 5 :
                     (hsn == 2 && tsn == 332) ? 7 :
                     (hsn == 2 && tsn == 333) ? 8 :
                     (hsn == 2 && tsn == 341) ? 5 :
                     (hsn == 2 && tsn == 342) ? 7 :
                     (hsn == 2 && tsn == 343) ? 8 :
                     (hsn == 2 && tsn == 411) ? 5 :
                     (hsn == 2 && tsn == 412) ? 8 :
                     (hsn == 2 && tsn == 413) ? 10 :
                     (hsn == 2 && tsn == 414) ? 10 :
                     (hsn == 2 && tsn == 421) ? 5 :
                     (hsn == 2 && tsn == 422) ? 5 :
                     (hsn == 2 && tsn == 423) ? 6 :
                     (hsn == 2 && tsn == 431) ? 7 :
                     (hsn == 2 && tsn == 432) ? 8 :
                     (hsn == 2 && tsn == 441) ? 7 :
                     (hsn == 2 && tsn == 442) ? 8 :

                     (hsn == 3 && tsn == 111) ? 3 :
                     (hsn == 3 && tsn == 112) ? 3 :
                     (hsn == 3 && tsn == 113) ? 5 :
                     (hsn == 3 && tsn == 121) ? 2 :
                     (hsn == 3 && tsn == 122) ? 3 :
                     (hsn == 3 && tsn == 123) ? 4 :
                     (hsn == 3 && tsn == 211) ? 5 :
                     (hsn == 3 && tsn == 212) ? 7 :
                     (hsn == 3 && tsn == 213) ? 10 :
                     (hsn == 3 && tsn == 214) ? 10 :
                     (hsn == 3 && tsn == 311) ? 4 :
                     (hsn == 3 && tsn == 411) ? 4 :
                     (hsn == 3 && tsn == 412) ? 7 :
                     (hsn == 3 && tsn == 413) ? 9 :
                     (hsn == 3 && tsn == 414) ? 10 :
                     (hsn == 3 && tsn == 421) ? 5 :

                     0;

   assign firstlic_0 = (firstlic > 30) ? 30 : firstlic;
   assign price_1 = price_0 + (firstlic_0 / 5) * 25;
   assign price_2 = (firstlic_0 > takerlic) ? price_1 + 30 : price_1 + 5;

   assign price = price_2;
   assign catcar = catcar_0;
endmodule // categorize_car

module age
  (
   input wire [7:0]  age,
   input wire [7:0]  age_threshold,
   output wire [7:0] result
   );
   assign result = age >= age_threshold;
endmodule // age

(* private *)
module driver
(
 input wire [39:0]  _inputs,
 output wire [15:0] _outputs
 );
   wire [7:0] age_driver;
   wire [7:0] policyholder;
   wire [7:0] drivers_under_25;
   wire [7:0] driving_license;
   wire [7:0] job;
   wire [15:0] result;
   assign age_driver = _inputs[7:0];
   assign policyholder = _inputs[15:8];
   assign drivers_under_25 = _inputs[23:16];
   assign driving_license = _inputs[31:24];
   assign job = _inputs[39:32];
   assign _outputs[15:0] = result;

   wire [15:0]      price_0;
   wire [15:0]      price_1;
   wire [15:0]      price_2;
   wire [15:0]      price_3;
   wire [15:0]      price_4;

   assign price_0 = (job == 0) ? 50 :
                    (job == 1) ? 35 :
                    (job == 2) ? 30 :
                    (job == 3) ? 25 :
                    (job == 4) ? 20 :
                    0;
   assign price_1 = price_0 + ((age_driver == 0) ? 65 : 0);
   assign price_2 = price_1 + ((policyholder == 0) ? 45 :
                               (policyholder == 1) ? 55 :
                               (policyholder == 2) ? 73 :
                               (policyholder == 3) ? 114 :
                               (policyholder == 4) ? 106 :
                               0);
   assign price_3 = price_2 + (13 * drivers_under_25);
   assign price_4 = price_3 + ((driving_license < 5) ? 73 : 0);

   assign result = price_4;
endmodule // driver

module damage
(
 input wire [31:0]  dmg1,
 input wire [31:0]  dmg2,
 input wire [7:0]   workshopthres,
 input wire [7:0]   yearsthres,
 input wire [31:0]  liabilitycosts,
 input wire [31:0]  partialcoveredcosts,
 input wire [31:0]  fullycomprehensivecosts,
 input wire [31:0]  workshopcosts,
 output wire [31:0] result
);
   wire [31:0]      percent_0;
   wire [31:0]      percent_1;
   wire [31:0]      percent_2;
   wire [31:0]      percent_3;
   wire [31:0]      tmp_0;
   wire [31:0]      tmp_1;
   wire [7:0]       dmg1_wscosts;
   wire [7:0]       dmg2_wscosts;
   wire [7:0]       dmg1_years;
   wire [7:0]       dmg2_years;
   assign dmg1_wscosts = dmg1[31:16] > workshopthres;
   assign dmg2_wscosts = dmg2[31:16] > workshopthres;
   assign dmg1_years = dmg1[7:0] <= yearsthres;
   assign dmg2_years = dmg2[7:0] <= yearsthres;

   assign tmp_0 = (dmg1[15:8] == 1) ? liabilitycosts :
                  (dmg1[15:8] == 2) ? partialcoveredcosts :
                  (dmg1[15:8] == 3) ? fullycomprehensivecosts :
                  0;
   assign percent_0 = (dmg1_years) ? tmp_0 : 0;
   assign percent_1 = percent_0 + ((dmg1_wscosts) ? workshopcosts : 0);
   assign tmp_1 = (dmg2[15:8] == 1) ? liabilitycosts :
                  (dmg2[15:8] == 2) ? partialcoveredcosts :
                  (dmg2[15:8] == 3) ? fullycomprehensivecosts :
                  0;
   assign percent_2 = percent_1 + ((dmg2_years) ? tmp_1 : 0);
   assign percent_3 = percent_2 + ((dmg2_wscosts) ? workshopcosts : 0);
   assign result = percent_3;
endmodule // damage

(* private *)
module location
(
 input wire [7:0]  location_input,
 output wire [7:0] result
);
   assign result = (location_input == 0) ? 12 :
                   (location_input == 1) ? 28 :
                   (location_input == 2) ? 46 :
                   (location_input == 3) ? 69 :
                   0;
endmodule // location

(* private *)
module flensburg
(
 input wire [7:0]   points,
 output wire [31:0] result
);
   assign result = (points != 0) ? 3276 : 0;
endmodule // flensburg

(* private *)
module car_usage
(
 input wire [15:0] _inputs,
 output wire [7:0] _outputs
);
   wire [7:0]      parkingspace;
   wire [7:0]      carusage;
   wire [7:0]      result;
   assign parkingspace = _inputs[7:0];
   assign carusage = _inputs[15:8];
   assign _outputs[7:0] = result;

   wire [7:0]      price_0;
   wire [7:0]      price_1;
   assign price_0 = (parkingspace == 0) ? 5 :
                    (parkingspace == 1) ? 15 :
                    (parkingspace == 2) ? 30 :
                    0;
   assign price_1 = price_0 + ((carusage) ? 25 : 5);
   assign result = price_1;
endmodule // car_usage

module calculate_basic_price
(
 input wire [15:0]  catcar,
 input wire [7:0]   location,
 input wire [15:0]  catdriver,
 input wire [7:0]   carusage,
 input wire [31:0]  damage,
 input wire [31:0]  flensburg_percent,
 output wire [31:0] result
);
   wire [31:0]      a;
   wire [31:0]      b;
   wire [31:0]      c;
   wire [31:0]      d;
   wire [31:0]      e;
   wire [31:0]      f;
   assign a = catcar << `FIXEDPOINT_FRACTION_BITS;
   fixedpt_mul tmp_c(a, flensburg_percent, c);
   assign d = location << `FIXEDPOINT_FRACTION_BITS;
   assign e = catdriver << `FIXEDPOINT_FRACTION_BITS;
   assign f = carusage << `FIXEDPOINT_FRACTION_BITS;
   assign result = a + b + c + d + e + f;
endmodule // calculate_basic_price

module saison
(
 input wire [7:0]   month,
 input wire [31:0]  price,
 output wire [31:0] result
);
   wire [31:0]      a;
   wire [31:0]      b;
   wire [31:0]      c;
   wire [31:0]      d;
   wire [31:0]      e;
   wire [31:0]      temp;
   wire [31:0]      pow;
   wire [31:0]      factor_0;
   wire [31:0]      factor_1;
   wire [31:0]      result_0;
   assign a = (12 - month) << `FIXEDPOINT_FRACTION_BITS;
   assign b = 12 << `FIXEDPOINT_FRACTION_BITS;
   fixedpt_div tmp_c(a, b, c);
   assign d = 78643;
   assign e = 52428;
   fixedpt_mul tmp_temp(c, 16384, temp);
   fixedpt_pow tmp_pow(d, -12 + (12 - month), pow);
   fixedpt_mul tmp_factor_0(temp + pow - 150732, e, factor_0);
   assign factor_1 = factor_0 + 49152;
   fixedpt_mul tmp_result_0(factor_1, price, result_0);
   assign result = -result_0;
endmodule // saison

(* private *)
module annual_drive
(
 input wire [47:0]  _inputs,
 output wire [31:0] _outputs
);
   wire [15:0]      annualdrivingdist;
   wire [31:0]      basicprice;
   wire [31:0]      result;
   assign annualdrivingdist = _inputs[15:0];
   assign basicprice = _inputs[47:16];
   assign _outputs[31:0] = result;

   wire [15:0]      annualdrivingdist_0;
   wire [7:0]       factor;
   wire [31:0]      a;
   wire [31:0]      price_0;
   wire [31:0]      price_1;
   assign annualdrivingdist_0 = (annualdrivingdist > 40000) ? 40000 : annualdrivingdist;
   assign factor = annualdrivingdist_0 / 5000;
   fixedpt_pow tmp_a(66846, factor, a);
   fixedpt_mul tmp_price_0(basicprice, a, price_0);
   assign price_1 = (a == 0) ? basicprice : price_0;
   assign result = price_1;
endmodule // annual_drive

module driver_person
(
 input wire [7:0]   damagefreeclasshp,
 input wire [7:0]   damagefreeclassvk,
 input wire [31:0]  price,
 output wire [31:0] pricehp,
 output wire [31:0] pricetk,
 output wire [31:0] pricevk
);
   wire [31:0]      helphp_0;
   wire [31:0]      helphp_1;
   wire [31:0]      helphp_2;
   wire [31:0]      helpvk_0;
   wire [31:0]      helpvk_1;
   wire [31:0]      helpvk_2;
   wire [31:0]      a;
   wire [31:0]      b;
   wire [31:0]      price_0;
   assign helphp_0 = 32768;
   assign helpvk_0 = 45875;

   assign a = damagefreeclasshp << `FIXEDPOINT_FRACTION_BITS;
   fixedpt_mul tmp_helphp_1(655, (a - (5 << `FIXEDPOINT_FRACTION_BITS)), helphp_1);
   assign helphp_2 = (damagefreeclasshp == 4) ? 36044 :
                     (damagefreeclasshp == 3) ? 39321 :
                     (damagefreeclasshp == 2) ? 45875 :
                     (damagefreeclasshp == 1) ? 55705 :
                     (damagefreeclasshp == 0) ? 65536 :
                     helphp_1;

   assign b = damagefreeclassvk << `FIXEDPOINT_FRACTION_BITS;
   fixedpt_mul tmp_helpvk_1(655, (b - (5 << `FIXEDPOINT_FRACTION_BITS)), helpvk_1);
   assign helpvk_2 = (damagefreeclassvk == 4) ? 49152 :
                     (damagefreeclassvk == 3) ? 55705 :
                     (damagefreeclassvk == 2) ? 62259 :
                     (damagefreeclassvk == 1) ? 68812 :
                     (damagefreeclassvk == 0) ? 75366 :
                     helpvk_1;

   fixedpt_mul tmp_price_0(price, 81920, price_0);
   fixedpt_mul tmp_pricehp(helphp_2, price_0, pricehp);
   fixedpt_mul tmp_pricetk(helpvk_2, price_0, pricetk);
   assign pricevk = pricetk;
endmodule // driver_person

module insurance_scope
(
 input wire [31:0]  pricehp,
 input wire [31:0]  pricetk,
 input wire [31:0]  pricevk,
 input wire [15:0]  selfpart,
 input wire [7:0]   paket,
 output wire [31:0] result
);
   wire [31:0]      price_0;
   wire [31:0]      price_1;
   wire [31:0]      price_2;
   wire [31:0]      price_3;
   wire [31:0]      price_4;
   wire [31:0]      temp_0;
   wire [31:0]      temp_1;
   wire [31:0]      temp_2;
   wire [31:0]      temp_3;
   wire [31:0]      temp_4;
   wire [31:0]      temp_5;
   wire [31:0]      temp_6;
   wire [31:0]      temp_7;
   wire [15:0]      helper;
   wire [15:0]      shifted_selfpart;

   assign helper = 9830;
   assign shifted_selfpart = selfpart << `FIXEDPOINT_FRACTION_BITS;

   assign price_0 = pricehp;

   assign price_1 = pricetk;
   assign temp_0 = 9830400;
   fixedpt_div tmp_temp_1(shifted_selfpart, temp_0, temp_1);
   fixedpt_mul tmp_temp_2(temp_1, helper, temp_2);
   fixedpt_mul tmp_temp_3(price_1, temp_2, temp_3);
   assign price_2 = price_1 - temp_3;

   assign price_3 = pricevk;
   assign temp_4 = 19660800;
   fixedpt_div tmp_temp_5(shifted_selfpart, temp_4, temp_5);
   fixedpt_mul tmp_temp_6(temp_5, helper, temp_6);
   fixedpt_mul tmp_temp_7(price_3, temp_6, temp_7);
   assign price_4 = price_3 - temp_7;

   assign result = (paket == 0) ? price_0 :
                   (paket == 1) ? price_2 :
                   (paket == 2) ? price_4 :
                   0;
endmodule // insurance_scope

module extras
(
 input wire [31:0]  price,
 input wire [7:0]   workshop,
 input wire [7:0]   marder,
 input wire [15:0]  categorizedcar,
 output wire [31:0] result
);
   wire [31:0]      adder_0;
   wire [31:0]      adder_1;
   wire [31:0]      a;
   wire [31:0]      tmp;
   assign adder_0 = (workshop) ? 5242 : 0;
   assign a = (categorizedcar + 1) << `FIXEDPOINT_FRACTION_BITS;
   fixedpt_mul tmp_tmp(a, 1310, tmp);
   assign adder_1 = adder_0 + ((marder) ? tmp : 0);
   fixedpt_mul tmp_result(adder_1, price, result);
endmodule // extras

module discount
(
 input wire [31:0]  price,
 input wire [7:0]   payment,
 input wire [7:0]   clubmember,
 input wire [7:0]   publictransport,
 input wire [7:0]   access,
 output wire [31:0] result
);
   wire [31:0]      discount_0;
   wire [31:0]      discount_1;
   wire [31:0]      discount_2;
   wire [31:0]      discount_3;
   assign discount_0 = (payment == 0) ? 0 :
                       (payment == 1) ? 655 :
                       (payment == 2) ? 1966 :
                       (payment == 3) ? 3276 :
                       0;
   assign discount_1 = discount_0 - ((clubmember) ? 3276 : 0);
   assign discount_2 = discount_1 - ((publictransport) ? 851 : 0);
   assign discount_3 = discount_2 - ((access) ? 983 : 0);
   fixedpt_mul tmp_result(price, discount_3, result);
endmodule // discount

module protletter
(
 input wire [31:0]  price,
 input wire [31:0]  extra_surcharge,
 input wire [31:0]  discount_surcharge,
 input wire [7:0]   protlet,
 output wire [31:0] result
);
   wire [31:0]      price_0;
   wire [31:0]      price_1;
   assign price_0 = price + extra_surcharge + discount_surcharge;
   assign price_1 = price_0 + ((protlet) ? 1245184 : 0);
   assign result = price_1;
endmodule // protletter
