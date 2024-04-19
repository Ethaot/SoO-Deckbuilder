using Godot;
using System;
using iTextSharp.text;
using System.IO;
using iTextSharp.text.pdf;
using System.Collections.Generic;
using static System.Net.Mime.MediaTypeNames;

public partial class DeckExporter : Node
{
	public override void _Ready() {
		//ImageTexture[] images = new ImageTexture[5];
		//images[0] = 
		/*List<iTextSharp.text.Image> images = new List<iTextSharp.text.Image>();
		images.Add(iTextSharp.text.Image.GetInstance("E:/_Docs/_CardGame/Deckbuilder/testimg0.png"));
		images.Add(iTextSharp.text.Image.GetInstance("E:/_Docs/_CardGame/Deckbuilder/testimg1.png"));
		images.Add(iTextSharp.text.Image.GetInstance("E:/_Docs/_CardGame/Deckbuilder/testimg2.png"));
		images.Add(iTextSharp.text.Image.GetInstance("E:/_Docs/_CardGame/Deckbuilder/testimg3.png"));
		images.Add(iTextSharp.text.Image.GetInstance("E:/_Docs/_CardGame/Deckbuilder/testimg4.png"));*/
		//CreatePDF();
	}
	public void CreatePDF(string path) {
		List<iTextSharp.text.Image> images = new List<iTextSharp.text.Image>();
		GD.Print(OS.GetUserDataDir() + "/tmp/");
		if (Directory.Exists(OS.GetUserDataDir() + "/tmp/")) {
			GD.Print("Directory tmp exists with " + Directory.GetFiles(OS.GetUserDataDir() + "/tmp/").Length + " files.");
			for (int i = 0; i < Directory.GetFiles(OS.GetUserDataDir() + "/tmp/").Length; i++) {
                if (File.Exists(OS.GetUserDataDir() + "/tmp/img" + i + ".png")) {
					images.Add(iTextSharp.text.Image.GetInstance(OS.GetUserDataDir() + "/tmp/img" + i + ".png"));
				}
            }			
		}
		Document doc1 = new Document(PageSize.LETTER);
		//path = "E:/_Docs/_CardGame/Deckbuilder/testPDF.pdf";
		PdfWriter.GetInstance(doc1, new FileStream(path, FileMode.Create));
		doc1.Open();
		foreach(iTextSharp.text.Image image in images) {
			doc1.NewPage();
            image.ScalePercent(37.511097744f);
            image.SetAbsolutePosition(36, 17);
            image.SetDpi(600, 600);
            doc1.Add(image);
        }		
		doc1.Close();
		CleanupImages();
	}
	void CleanupImages() {
        if (Directory.Exists(OS.GetUserDataDir() + "/tmp/")) {
            for (int i = Directory.GetFiles(OS.GetUserDataDir() + "/tmp").Length; i >= 0; i--) {
                if (File.Exists(OS.GetUserDataDir() + "/tmp/img" + i + ".png")) {
					//images.Add(iTextSharp.text.Image.GetInstance("user://tmp/img" + i + ".png"));
					File.Delete(OS.GetUserDataDir() + "/tmp/img" + i + ".png");
                }
            }
        }
    }
}
