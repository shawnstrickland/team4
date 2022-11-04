import pdf from 'html-pdf'
import AWS from 'aws-sdk'
import nunjucks from 'nunjucks'

process.env.PATH = `${process.env.PATH}:/opt`

let OUT_PDF_OPTIONS = {"format":"Letter", "orientation": "landscape", "border": '15mm', "zoomFactor": "0.6"};
let PDF_UPLOAD_ARGS = {ContentType: 'application/pdf', ACL:'public-read'};
let OUTPUT_PDF_NAME_POSTFIX = ".pdf"

const s3 = new AWS.S3();
console.log(s3);
(async () => {
    try {
        // let payload = event

        // Sample payload to use
        let payload = {
            template_dynamic_data: 'string',
            template_s3_bucket_details: {
                OBJECT_KEY: 'string',
                BUCKET_NAME: 'string'
            },
            pdf_s3_bucket_details: {
                BUCKET_NAME: '',
                PDF_FILE_INFO: {
                    PATH: '',
                    PDF_GENERATION_OPTION: '',
                    PDF_UPLOAD_EXTRA_ARGS: {
                        
                    }
                }
            },
            version: 'string',
            resource_lock_id: 'string',
        }

        let transform_payload = transform_inputs(payload);

        console.log(transform_payload)
         
        // template bucket details        
        let template_s3_bucket = transform_payload.template_s3_bucket_details.BUCKET_NAME
        let template_s3_key = transform_payload.template_s3_bucket_details.OBJECT_KEY
 
        // Bucket details for storing PDF generated        
        let pdf_bucket = transform_payload.pdf_s3_bucket_details.BUCKET_NAME;
        let pdf_file_info = transform_payload.pdf_s3_bucket_details.PDF_FILE_INFO;
        let pdf_file_path = pdf_file_info.PATH
        
        if (pdf_file_path && pdf_file_path.split('.').length > 1 && (!pdf_file_path.endsWith(OUTPUT_PDF_NAME_POSTFIX))){
            console.log('Incorrect pdf file extension')
            return {
            'statusCode': 400,
            'body': JSON.stringify({"message": "Incorrect pdf file extension"})
            }
        }
        if (pdf_file_path && pdf_file_path.split('.').length == 1){
            pdf_file_path = pdf_file_path + OUTPUT_PDF_NAME_POSTFIX
        }
        let pdf_generation_options = pdf_file_info.PDF_GENERATION_OPTION;
        let pdf_upload_extra_args = pdf_file_info.PDF_UPLOAD_EXTRA_ARGS;        
        // Dynamic data for rendering PDF
        let render_data = transform_payload.template_dynamic_data
        
        // Data for queuing purpose
        let version = transform_payload.version
        let resource_lock_id = transform_payload.resource_lock_id

        // template Object
        let Data = await s3.getObject({ Bucket: template_s3_bucket, Key: template_s3_key }).promise();
        
        // Body will be a buffer type so need to convert it to string before converting to pdf
        let html = Data.Body.toString();
        let template = nunjucks.compile(html);        
        // Dynamic data rendered into the template
        let content = template.render(render_data);        
        let options = OUT_PDF_OPTIONS;
        if (pdf_generation_options && Object.keys(pdf_generation_options).length){
            options = pdf_generation_options;
        }        
        // PDF generation
        let file = await exportHtmlToPdf(content, options);

        // PDF upload to s3
        let upload_args = PDF_UPLOAD_ARGS;
        if (pdf_upload_extra_args && Object.keys(pdf_upload_extra_args).length){
            upload_args = pdf_upload_extra_args
        }
        upload_args.Bucket = pdf_bucket
        upload_args.Key = pdf_file_path
        upload_args.Body = file
        let file_upload_data = await s3.upload(upload_args).promise();

        // Response formatting
        let message = ''
        let url = ''
        let status
        if (file_upload_data.Location){
            status = 200
            url = file_upload_data.Location
            message = 'PDF generated successfully'
        }
        else{
            status = 400
            url = ''
            message = 'Error in generating pdf'
        }
        let response_message = {
            'message': message,
            'version': version,
            'resource_lock_id': resource_lock_id
        }
        let body = {"message": response_message,
            "url": url}
    return {
            'statusCode': status,
            'body': JSON.stringify(body)
    }
    } catch (error) {
        return {
         'statusCode': 500,
         'body': JSON.stringify(error)
        }
    }
})();

const transform_inputs = payload => {
    let template_dynamic_data = payload.template_dynamic_data
    let template_s3_bucket_details = payload.template_s3_bucket_details
    let pdf_s3_bucket_details = payload.pdf_s3_bucket_details
    let version = payload.version
    let resource_lock_id = payload.resource_lock_id
    return {'template_dynamic_data': template_dynamic_data,
            'template_s3_bucket_details': template_s3_bucket_details,
            'pdf_s3_bucket_details': pdf_s3_bucket_details,
            'version':version, 'resource_lock_id': resource_lock_id}
    }

const exportHtmlToPdf = async (html, options) => {
    return new Promise((resolve, reject) => {
        options.phantomPath= "/opt/phantomjs_linux-x86_64";
        pdf.create(html, options).toBuffer((err, buffer) => {
            if (err) {
                console.log('Error in exportHtmlToPdf')
                reject(err)
            } else {
                resolve(buffer)
            }
        });
    })
}