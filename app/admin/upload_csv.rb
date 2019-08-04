ActiveAdmin.register_page "Upload Csv" do
  
page_action :import_listings, method: :post do
  #redirect_to admin_upload_csv_path , notice: "CSV imported successfully!"
end

  content do
    columns do
      column do
        panel 'PLease Upload CSV' do
          ul do
            render 'admin/csv/upload_csv'
          end
        end
      end
    end
  end

  controller do 
    require 'csv'
    def import_listings
      begin
        convert_save(params[:company_id], params[:file])
        msg = {notice: "Csv imported successfully."}
      rescue => e
        msg = {alert: e.message}
      end
        redirect_to admin_upload_csv_path, msg
    end  
    
    def convert_save(company_id, csv_data)
        if company_details(company_id) || csv_data.content_type != "text/csv"
          csv_file = csv_data.read
          CSV.parse(csv_file, :headers => true) do |row|
            
            next if row == ["Employee Name", "Email", "Phone", "Report To", "Assigned Policies"]
        
            if row["Employee Name"].present? && row["Email"].present?
              create_company_record(row["Employee Name"], row["Email"], row["Phone"], company_id, row["Report To"], row["Assigned Policies"])
            else
              raise "You are trying to save incorrect data" 
            end  
          end
        else
           raise "You are trying to save incorrect data" 
        end 
    end


    def company_details(company_id)
      return Company.find_by(id: company_id).present? ? true : false
    end

    def create_boss_record(email, company_id)
      boss_data = Employee.find_or_initialize_by(email: email, company_id: company_id)
      boss_data.name = email.partition("@").first
      boss_data.save
    end

    def create_company_record(emp_name, email, phone, company_id, boss, policy_data)
      create_boss_record(boss, company_id)      if boss.present?
      

      emp_data = Employee.find_or_initialize_by(email: email,  company_id: company_id)
      emp_data.name = emp_name
      emp_data.phone =  phone.present? ? phone : ""  
      emp_data.save

      emp_data.policies.destroy_all
      create_policy_record(policy_data, company_id, emp_data) 
    end
    
      def create_policy_record(policy_data, company_id, emp_data)
          policy_data.split("|").each do |policy|
            policy_recd = Policy.find_or_create_by(company_id: company_id, name: policy)
            emp_data.policies << policy_recd
          end
      end 
 
    #end

  end

end



