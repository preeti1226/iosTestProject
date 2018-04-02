

import UIKit


class UserProfileDetailsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{
   
    @IBAction func nextBtn(_ sender: Any) {
        self.performSegue(withIdentifier: "UserImageSegue", sender: self)
        
    }
    @IBOutlet var userProfileTableView: UITableView!
    let userInfoLbl=["Store","City","Mobile","EmpCode","CounterCode"]
    let userInfo=[userdt.data[0].CurrentStore,userdt.data[0].City,userdt.data[0].Pmobile1,userdt.data[0].EmployeeCode,userdt.data[0].CounterCode]
    override func viewDidLoad() {
        super.viewDidLoad()
        userProfileTableView.delegate=self;
        userProfileTableView.dataSource=self;
       
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userInfoLbl.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell=userProfileTableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text=userInfoLbl[indexPath.row]
        cell?.detailTextLabel?.text=userInfo[indexPath.row]
    //    let btn = cell?.viewWithTag(100) as! UIButton
    
        return cell!
    }
    
}
