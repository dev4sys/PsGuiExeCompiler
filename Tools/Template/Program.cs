using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using System.Threading;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows;

namespace starter
{
    class Program 
    {

        // class attributes
        private static Mutex _mutex;  // MUTEX
        private static string _toolName = "%toolName%";
        private static string _namespaceName = "";
        private static bool _singleInstance = %mutex% ;

        // Static Methods
        private static string GetResourceNameFromFileName(string fileName) {

            StringBuilder builder = new StringBuilder(fileName);
            builder.Replace("\\", ".");
            builder.Replace("-", "_");
            builder.Replace(" ", "_");

            return builder.ToString();
        }

        private static String[] GetFilesStructure()
        {

            // this file should always be there to retrieve the hierarchy of the folder.
            string directoryStruct = _namespaceName + ".directory.inf";
            Stream stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(directoryStruct);

            StreamReader streamReader = new StreamReader(stream);
            string result = streamReader.ReadToEnd();
            String[] res = result.Split(new[] { Environment.NewLine }, StringSplitOptions.None);

            // return an array of files of the application.
            return res;

        }

        private static void CreateToolFolder(string zerosPadding) {

            // get the current user Temp path 
            string tempFolder = Path.GetTempPath();
            string location = tempFolder + zerosPadding + _toolName;

            if (!Directory.Exists(location))
            {
                Directory.CreateDirectory(location);
            }

        }

        private static bool CreateResourceFile(string zerosPadding, string filename)
        {

            // get the current user Temp path 
            string tempFolder = Path.GetTempPath();
            string location = tempFolder + zerosPadding + _toolName;
            string filepath = location + filename;

            // check if the folder does not exist beforehand
            string folder = Path.GetDirectoryName(filepath);
            if (!Directory.Exists(folder))
            {
                Directory.CreateDirectory(folder);
            }

            // create the file then
            string resourceName = _namespaceName + ".Resources" + GetResourceNameFromFileName(filename);

            var resource = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName);
            try
            {
                using (FileStream file = new FileStream(filepath, FileMode.Create, FileAccess.Write))
                {
                    resource.CopyTo(file);
                    //file.Dispose();
                    //file.Close();
                }
            }
            catch {
                Console.WriteLine("Error occurred");
            }
            return true;

        }

        private static void CreateStructureFile(string zerosPadding, string[] rawResourceNames) {

            bool status = true;
            // create resources files at temp folder from th embedded resources.
            if (rawResourceNames != null || rawResourceNames.Length < 1){

                foreach (string lines in rawResourceNames) {

                    if (!string.IsNullOrEmpty(lines)) {

                        if (!lines.Contains("directory.inf")) // skip if it's directory.inf file
                        {
                            bool iRet = CreateResourceFile(zerosPadding,lines);
                            status = status && iRet;
                        }

                    }
                }   
            }
            else
            {
                Console.WriteLine("Null or empty string array.");
            }

            // check if everythoing is OK.
            if (status) {
                Console.WriteLine("Everything is OK");
                // everything is OK
            }

        }

        public static void BeginProcess(string zerosPadding, string script) {

            // get the current user Temp path 
            string tempFolder = Path.GetTempPath();
            string workingDir = tempFolder + zerosPadding + _toolName;
            
            string mainScript = workingDir + "\\" + script;
            string outputConsole = workingDir + "\\log.txt";

            if (File.Exists(mainScript))
            {

                var process = new Process();

                process.StartInfo.UseShellExecute = false;
                process.StartInfo.RedirectStandardOutput = true;
                process.StartInfo.WorkingDirectory = workingDir;
                process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
                process.StartInfo.CreateNoWindow = true;
                process.StartInfo.FileName = @"C:\windows\system32\windowspowershell\v1.0\powershell.exe";
                process.StartInfo.Arguments = "-WindowStyle Hidden -noProfile -executionpolicy bypass \"" + mainScript + "\"";

                process.Start();
                string s = process.StandardOutput.ReadToEnd();
                process.WaitForExit();

                using (StreamWriter outfile = new StreamWriter(outputConsole, true))
                {
                    outfile.Write(s);
                }
				
            }
            else
            {
                MessageBox.Show("Main script not found!");
            }
        }
        
        // Main function
        static void Main(string[] args)
        {

            _namespaceName = Assembly.GetExecutingAssembly().GetName().Name;

            // get the list of all processes by that name
            string procName = Process.GetCurrentProcess().ProcessName;
            Process[] processes = Process.GetProcessesByName(procName);

            // retrieve all list of the Resources to embed
            string[] _resources = Assembly.GetExecutingAssembly().GetManifestResourceNames();
            Assembly assembly = Assembly.GetExecutingAssembly();

            Console.WriteLine(string.Join(Environment.NewLine,Assembly.GetEntryAssembly().GetManifestResourceNames()));

            // get the structure of the files to recreate the folders in temp folder
            string[] res = GetFilesStructure();

            bool createdNew;
            _mutex = new Mutex(true, _toolName, out createdNew);
            if (_singleInstance)
            {
                
                if (createdNew)
                {
                    string zeros = "0000";
                    // create tool folder in  user temp folder
                    CreateToolFolder(zeros);
                    // create resource files to be executed.
                    CreateStructureFile(zeros,res);
                    // Launch the powershell script
                    BeginProcess(zeros,"%mainScript.ps1%");
                }
                else
                {
                    MessageBox.Show("The application is already running.");
                }
            }
            else
            {

                int occurrence = processes.Length;
                string zerosPads = String.Format("{0:D4}", occurrence); // return a string 0001
                // create tool folder in  user temp folder
                CreateToolFolder(zerosPads);
                // create resource files to be executed.
                CreateStructureFile(zerosPads,res);
                // Launch the powershell script
                BeginProcess(zerosPads,"%mainScript.ps1%");

            }

        }

    }
}
