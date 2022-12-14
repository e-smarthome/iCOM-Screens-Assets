//
//  ControlDeviceViewModel.swift
//  DemoX
//
//  Created by Nam Nguyễn on 19/11/2022.
//

import RxSwift
import RxCocoa
import iCOM_Service

final class ControlDeviceViewModel: BaseViewModel {
    let pSLoadingBlockUI = PublishSubject<Bool>()
    let pSGetList = PublishSubject<[Items]>()
    
    private var disposeRq: Disposable?
    
    var allListDevices = [Items]()
    var arrSection = [String]()
    var arrItem = [[Items]]()
    var powerConsum = Int()
    
    
    deinit {
        disposeRq?.dispose()
    }
    
    func filterSection() {
        arrSection.removeAll()
        arrSection.append("")
        for item in allListDevices {
            if let deviceType = item.deviceType {
                if !arrSection.contains(deviceType) {
                    arrSection.append(deviceType)
                }
            }
        }
        
        StoreData.shared.setListSections(listSections: arrSection)
    }
    
    func filterItem() {
        arrItem.removeAll()
        var item = [Items]()
        for value in arrSection {
            for _item in allListDevices {
                if let deviceType = _item.deviceType {
                    if value == deviceType {
                        item.append(_item)
                    }
                }
            }
            arrItem.append(item)
            item.removeAll()
        }
        
        print(arrItem)
        
        StoreData.shared.setListItems(dictData: arrItem)
    }
}

extension ControlDeviceViewModel {
    
    func loadListDevices() {
        self.pSLoadingBlockUI.onNext(true)
        allListDevices.removeAll()
        
        let request = ControlDeviceModel.ListDevice()
        
        APIClient.shared.listDevices(params: request)
            .map({ (response) -> [Items] in
                self.powerConsum = response.powerConsumption ?? 0
                return response.items ?? [Items]()
            })
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .userInitiated))
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [unowned self] data in
                    self.pSLoadingBlockUI.onNext(false)
                    self.allListDevices.append(contentsOf: data)
                    filterSection()
                    filterItem()
                    pSGetList.onNext(allListDevices)
                },
                onError: { [unowned self] error in
                    self.pSLoadingBlockUI.onNext(false)
                    print(error)
            }).disposed(by: disposeBag)
    }
    
    func loadOnOffDevice(mac: String, status: Bool) {
        self.pSLoadingBlockUI.onNext(true)
        
        let request = HomeModel.ControlDevice(mac: mac, status: status)
        
        APIClient.shared.onOffDevice(params: request)
            .map({ (response) -> OnOffDevice in
                return response 
            })
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .userInitiated))
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [unowned self] data in
                    self.pSLoadingBlockUI.onNext(false)
                },
                onError: { [unowned self] error in
                    self.pSLoadingBlockUI.onNext(false)
                    print(error)
            }).disposed(by: disposeBag)
    }
    
    
}


