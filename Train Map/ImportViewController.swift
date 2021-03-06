//
//  ViewController.swift
//  Ticket To Ride
//
//  Created by Tom Curtis on 24 Jul 2016.
//  Copyright © 2016 Tom Curtis. All rights reserved.
//

import Cocoa


class ImportViewController: NSViewController {
    
    var progressViewController: ImportProgressViewController?
    var pendingOperations: PendingOperations!
    
    // Retreive the managedObjectContext from AppDelegate
    let mainMOC: NSManagedObjectContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //Find and load new data set
    @IBAction func loadNewData(_ sender: AnyObject) {
    
        //data file types to use
        let dataFileTypes: [String] = ["alf", "mca", "msn", "ztr"]
     
        //file chooser dialog
        let dialog: NSOpenPanel = NSOpenPanel()
        dialog.title                   = "Select a data file"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = dataFileTypes

        if (dialog.runModal() == NSModalResponseOK) {
            dialog.performClose(nil)
            
            //display the progress dialog box
            if let pvc: ImportProgressViewController = storyboard!.instantiateController(withIdentifier: "importProgressViewController") as? ImportProgressViewController {
                self.progressViewController = pvc
                presentViewControllerAsSheet(self.progressViewController!)
                self.progressViewController!.importController = self
            }
            
            //now launch the importing operation
            self.pendingOperations = PendingOperations()
            let ttisImport: ttisImporter = ttisImporter(chosenFile: dialog.url!, progressViewController: progressViewController)
            ttisImport.completionBlock = {
                if ttisImport.isCancelled {
                    ttisImport.MOC.rollback()
                    return
                }
                //close the progress view controller and let the user know
                DispatchQueue.main.async(execute: {
                    //do stuff to refresh main display
                    self.progressViewController?.dismiss(self)
                    let alert: NSAlert = NSAlert();
                    alert.alertStyle = NSAlertStyle.informational
                    alert.messageText = "Import complete";
                    alert.informativeText = "Successfully completed import of new data."
                    alert.runModal();
                })
                self.view.window!.close() //close the import window
                
            }
            self.pendingOperations.importsInProgress.append(ttisImport) //add to queue to keep track of it
            self.pendingOperations.importQueue.addOperation(ttisImport)
        }
        else {
            // User clicked on "Cancel"
            return
        }
    }
    
    @IBAction func cancelImports(_ sender: AnyObject) {
        if (self.pendingOperations != nil) {
            self.pendingOperations.importsInProgress = []
            self.pendingOperations.importQueue.cancelAllOperations()
        }
        self.view.window!.close()
    }
    
}
