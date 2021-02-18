//
//  ViewController.swift
//  Stocks
//
//  Created by Светлана Романенко on 31.01.2021.
//

import UIKit

final class ViewController: UIViewController {
    
    //MARK: - IB Outlets
    
    @IBOutlet var companyNameLabel: UILabel!
    @IBOutlet var priceChangeLabel: UILabel!
    @IBOutlet var companySymbolLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    
    @IBOutlet var companyPickerView: UIPickerView!
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    @IBOutlet var logoImage: UIImageView!
    
    //MARK: - Private properties
    
    private lazy var companies = [
        "Apple": "AAPL",
        "Microsoft": "MSFT",
        "Google": "GOOG",
        "Amazon": "AMZN",
        "Facebook": "FB"
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        companyNameLabel.text = "Tinkoff"
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        
        requestQuoteUpdate()
    }
}

// MARK: - UIPickerViewDataSource

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }

    // MARK: - Private
    
    private func parseQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double,
                let logoImage = json["logos"] as? UIImage
            else {
                return print("Invalid JSON")
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName,
                                       companySymbol: companySymbol,
                                       price: price,
                                       priceChange: priceChange)
            }
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func displayStockInfo (companyName: String,
                                   companySymbol: String,
                                   price: Double,
                                   priceChange: Double) {
        activityIndicator.stopAnimating()
        companyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        
        switch priceChange {
        case 0:
            priceChangeLabel.textColor = .black
        case 0...:
            priceChangeLabel.textColor = .green
        case ..<0:
            priceChangeLabel.textColor = .red
        default:
            break
        }
        priceChangeLabel.text = "\(priceChange)"
    }
    
    private func requestQuote(for symbol: String) {
        let token = "pk_5949bbf8a9a5406387e6e322dd2f1c1b"
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data,
               (response as? HTTPURLResponse)?.statusCode == 200,
               error == nil {
                self.parseQuote(from: data)
            } else {
                print("Network error!")
            }
        }
        
        dataTask.resume()
    }
    
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        priceChangeLabel.textColor = .black
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
}
    
    func pickerView(_ pickerView: UIPickerView, didSelectedRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
}

// MARK: - UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        activityIndicator.startAnimating()
        
        let selectedSymbol = Array(companies.values)[row]
        requestQuote(for: selectedSymbol)
    }
}

