//
//  ContentView.swift
//  Wlog
//
//  Created by Pranav on 7/17/23.
//

import SwiftUI
import Supabase
import Charts

struct WeightLog: Codable {
    let date: Date
    let weights: Double
}

let client = SupabaseClient(supabaseURL: URL(string:"https://xyzcompany.supabase.co")!, supabaseKey: "public-anon-key")



struct ContentView: View {
    
    @State var weightLogs : [WeightLog] = []
    @State var showAddLogOverlay = false
    @State var dateIsDone = false
        
    func load() async{
        weightLogs = try! await client.database.from("w").execute().value
        weightLogs = weightLogs.sorted {
            $0.date >= $1.date
        }
        let date = Date()

        let components1 = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let components2 = Calendar.current.dateComponents([.year, .month, .day], from: weightLogs[0].date)
        if components1 == components2{
            dateIsDone = true
        }
        
    }
    
    var body: some View {
        NavigationView{
            ZStack{
                VStack{
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Chart{
                        ForEach(weightLogs, id:\.date) { log in
                            LineMark(x: .value("Date",log.date), y: .value("weight",log.weights))
                        }
                    }
                    .chartYScale(domain: [160, 170])
                    .frame(width: 400, height: 100, alignment: .bottom)
                    .foregroundColor(Color.green)
                    Spacer()
                }
                List{
                    
                    ForEach(Array(weightLogs), id: \.date) { weightLog in
                        HStack{
                            Text("\(weightLog.date.formatted(date:.abbreviated, time: .omitted))")
                            Spacer()
                            Text("\(weightLog.weights , specifier: "%.1f")  lbs")
                            
                        }
                    }
                }
                .opacity(0.3)

            }
                .navigationTitle("Log")
                .toolbar{
                    Button(action: {
                        showAddLogOverlay.toggle()
                        dateIsDone.toggle()
                        
                    }){
                        Text(" + ")
                    }
                    .disabled(dateIsDone)
                }

                
                 
            }
        .onAppear{
            Task{
                await load()
            }
        }
        .sheet(isPresented: $showAddLogOverlay){
            AddLogOverlay(weightLogs: $weightLogs)
        }
        
            
    }
}

struct AddLogOverlay:View{
    
    @Environment(\.dismiss) var dismiss
    @Binding  var weightLogs : [WeightLog]
    @State var currentWeight : Double = 0
    @State var date : Date = Date()

    
    func insert(weights: Double) async{
        @State var log = WeightLog(date:Date(), weights:weights)
        weightLogs.insert(log, at: 0)
        try! await client.database
              .from("w")
              .insert(values: log)
              .execute()

    }
    
    func addLog(date: Date, weights: Double){
        
        @State var log : WeightLog = WeightLog(date: Date(), weights: weights)
        weightLogs.insert(log, at: 0)
    }
    
    var body: some View{
        
        NavigationView{
            Form{
                Section(header: Text("Cur")){
                    TextField("Weight(lbs)", value: $currentWeight, format: .number)
                }
            }
            .navigationTitle("Add W")
            .toolbar{
                Button(action: {
                    
                    Task{
                        await insert(weights: currentWeight)
                    }
                    dismiss()
                    
                }){
                    Text("Save")
                }
                
            }
        }
        
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
