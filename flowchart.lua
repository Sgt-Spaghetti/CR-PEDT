--[[

	Setting up all the possible Questions
	implemented as a singly-linked tree

--]]

local Question = {}

function Question:new(txt, yes, no, yes_lbl, no_lbl)

	local object = {}
	self.__index = self
	setmetatable(object, self)

	object.text = txt
	object.yes = yes
	object.no = no
	object.yes_label = yes_lbl
	object.no_label = no_lbl

	return object
end

function Question:ask()
	return self.text
end

--[[

	TUI stuff

--]]

local esc = string.char(27)
local esc_csi = esc .. "["
local cursor_home = esc_csi .. "H"
local cursor_moveto = function (x, y) return table.concat({esc_csi,tostring(y),";",tostring(x),"H"}) end
local cursor_position = esc_csi .. "6n"
local cursor_clearline = esc_csi .. "2K"
local clear_screen = esc_csi.."2J"
local text_underline = function(text) return table.concat({esc_csi, "4m",text, esc_csi,"24m"}) end
local text_bold = function(text) return table.concat({esc_csi, "1m", text, esc_csi,"22m"}) end
local text_dim = function(text) return table.concat({esc_csi, "2m", text, esc_csi,"22m"}) end
local text_italic = function(text) return table.concat({esc_csi, "3m", text, esc_csi,"23m"}) end
local text_blinking = function(text) return table.concat({esc_csi, "5m", text, esc_csi,"25m"}) end
local padx = 10
local pady = 8

local fg_colours = {
["black"] = ";30",
["red"] = ";31",
["green"] = ";32",
["yellow"] = ";33",
["blue"] = ";34",
["magenta"] = ";35",
["cyan"] = ";36",
["white"] = ";37",
["default"] = ";39",
["reset"] = ";0",
}

local bg_colours = {
["black"] = ";40",
["red"] = ";41",
["green"] = ";42",
["yellow"] = ";43",
["blue"] = ";44",
["magenta"] = ";45",
["cyan"] = ";46",
["white"] = ";47",
["default"] = ";49",
["reset"] = ";0",
}

function colour_text(text, fg, bg)
	if text ~= nil then
		local fg = fg or "default"
		local bg = bg or "default"
		local reset = esc_csi .. "0m"
		return table.concat({esc_csi, fg_colours[fg], bg_colours[bg],"m", text, reset})
	else return text end
end


--[[
	Run the program!
--]]

-- Manually writing the questions

local question_insertion_site = Question:new("Have you decided a chloroplast insertion site and flanking sequence?", nil, nil, "Check the insertion site you want to use isn't already occupied by a previous insertion.", nil)
local question_selection_strain = Question:new("Will you be using a selection strain? (HNT6, HT72, psaA**)", question_insertion_site, question_insertion_site, nil, nil)
local question_general_strain = Question:new("Will you be expressing in a wild type strain or strains that are cell wall deficient, non-motile, yellow in the dark, capable of growth on phosphite, etc.?)",question_selection_strain, question_selection_strain, nil, nil)
local question_gene_synthesis = Question:new("Will you be employing parts-wise assembly for the genetic construct?", question_general_strain, question_general_strain, nil, nil)
local question_loop_out = Question:new("Do you want to loop out the selectable marker?", question_gene_synthesis, question_gene_synthesis, nil, nil)
local question_selection_marker = Question:new("Will you use any selectable markers?", question_loop_out, question_gene_synthesis, nil, nil)
local question_cis_elements = Question:new("Have you decided which cis-elements are needed? (promoters, ribosome binding sites, terminators, 3' UTR)", question_selection_marker, question_selection_marker, "Remember to take into account that there are a limited number of cis-elements available, and if possible they should not be reused", nil)
local question_codon_reassignment = Question:new("Will there be codon reassignment?", question_cis_elements, question_cis_elements, nil, nil)
local question_codon_optimisation = Question:new("Will the coding sequence be codon optimised?", question_codon_reassignment, question_codon_reassignment, nil, nil)
local question_termini_2 = Question:new("Will the tag be inserted at the N terminus?", question_codon_optimisation, question_codon_optimisation, nil, nil)
local question_reporter = Question:new("Will you be adding a reporter tag for cell localisation assays?", question_termini_2, question_codon_optimisation, "mVenus and mScala are proven fluorescent localisation tags.", nil)
local question_termini_1 = Question:new("Will the tag be added at the N terminus?", question_reporter, question_reporter, nil, nil)
local question_epitope_purification = Question:new("Will you use an epitope or purification tag?", question_termini_1, question_reporter, nil, nil)
local question_tag = Question:new("Will you tag the protein?", question_epitope_purification, question_codon_optimisation, nil, nil)
local question_N_terminus = Question:new("Would the protein be modified at the N-terminus? (stabilising or destabilising residues)", question_tag, question_tag, nil, nil)
local question_restriction_sites = Question:new("Are there unwanted restriction sites in the DNA sequence?", question_N_terminus, question_N_terminus, "Make sure to remove all unwanted sites through changing the codons used.", nil)
local question_mature_protein = Question:new("Is the protein natively expressed as a pre-protein?", question_restriction_sites, question_restriction_sites, "In many cases the protein expressed in Chlamy must be mature, i.e potentially remove transit peptides.", nil)
local question_disulphide_bonds = Question:new("Does the protein require disulphide bonds?", question_mature_protein, question_mature_protein, "Attach a transit peptide to the protein in order to direct it to the stroma, grow the algae in heterotrophic conditions as the oxidising status of stroma is higher. Alternatively target the protein into the lumen as it is much more oxidising then stroma. Take into account whether to use the Sec/Tat pathway, depending on if the protein can be unfolded or not (does it require cofactors?).", nil)
local question_oligomerisation = Question:new("Does the protein oligomerise?", question_disulphide_bonds, question_disulphide_bonds)
local question_ptm = Question:new("Is the protein post-translationally modified?",question_oligomerisation,question_oligomerisation)
local question_solubility = Question:new("Is the protein expected to be readily soluble? (use https://protein-sol.manchester.ac.uk/)", question_ptm, question_ptm)
local question_protein_size = Question:new("Is the protein small? (<30 amino acids)", question_solubility, question_solubility, "Note that small peptides are treated as transit peptides in the chloroplast, they quickly targeted for degradation. Add a tag to the protein in order to increase its size.", "If the protein is <100kDa, we can safely assume size will not be an issue for protein expression.")
local question_e_coli_toxicity = Question:new("Is the protein likely to be toxic in E. coli?", question_protein_size, question_protein_size, "Insert stop codons into the coding sequence using the recoded tryptophan codon system, or reassign any key active serine to argenine using the argenine-recoding system.", nil)
local question_protein_cofactors = Question:new("Are all the required protein cofactors present in the chloroplast? Consider prosthetic groups (haeme, flavin, etc.), co-enzymes (NAD+, FAD, CoA, etc.) and metal ions (Fe, Cu, Zn, etc.)", question_e_coli_toxicity, question_e_coli_toxicity, nil, nil)
local question_chloroplast_toxicity = Question:new("Is the protein likely to be toxic in the chloroplast?", question_protein_cofactors, question_protein_cofactors, "Decide if gene expression has to be regulated by: 1. Pawel's vitamin induction system that regulates mRNA stability/translation initiation; 2. Temperature sensitive versions of tryptophan tRNA or tags which trigger degradation and can be used to control protein levels post-translationally; 3. The Jungle Express system can be used for control of protein expression post-transcription.", nil)
local question_protein_number = Question:new("Do you wish to express multiple proteins?", question_chloroplast_toxicity, question_chloroplast_toxicity,"Consider multigenic strategies: 1. Separate transcriptional units (each needs distinct promoter and UTR elements). 2. Operon (needs validated IEEs). 3. Translation fusions (need flexible linkers or specific proteolytic cleavage site at junction).", nil)

--[[
	Starting the main loop
--]]

function main()

	-- Keep track of answered questions in order to provide
	-- a recorded summary at the end of the flowchart.

	local answered_questions = {}
	
	function wrap_text(text, width)
		if text ~= nil then
			local output = {}
			if #text > width then
				local pos = 1
				for i=1, math.ceil(#text/width) do
					if i == math.ceil(#text/width) then
						output[#output+1] = string.sub(text, pos, #text).."\n"
					else
						local offset = 0
						if string.sub(text, pos+width, pos+width) ~= " " then
							while true do
								offset = offset + 1
								if string.sub(text, pos+width-offset, pos+width-offset) == " " then 
									break
								end
							end
						end
						output[#output+1] = string.sub(text, pos, pos+width-offset).."\n"
						pos = pos + width - offset
					end
				end
				return output
			else
				output[1] = text .. "\n"
				return output
			end
		end	
		
	end
	
	function print_answered_questions()
		local text_width = 60
		local frame_width = 80
		io.write(table.concat({clear_screen,cursor_home,colour_text("\n\nSession Summary:\n\n","magenta")}))
		for  i=1, #answered_questions do
			local question = wrap_text(answered_questions[i][1], text_width)
			local answer = wrap_text(answered_questions[i][3], text_width)
			question[1] = string.gsub(question[1],"\n", " ") .. string.rep(" ", frame_width - #question[1] - 3)
			io.write(question[1], answered_questions[i][2])
			if #question > 1 then
				for i=2, #question do
					io.write(question[i])
				end
			end
			if answer ~= nil then
				for i=1, #answer do
					io.write(colour_text("| "..answer[i],"yellow"))
				end
			end
			io.write("\n")
			
		end
	end

	io.write(clear_screen)
	io.write(cursor_moveto(padx+4, 2))
	io.write(colour_text(text_underline("Chlamydomonas Reinhartii"), "magenta"))
	io.write(cursor_moveto(padx, 4))
	io.write(text_dim("Protein Expression Decision Tree"))

	local active_question = question_protein_number
	local running = true

	while running == true do

		io.write(cursor_moveto(padx, pady))
		io.write(cursor_clearline)
		io.write(active_question:ask())
		io.write(cursor_moveto(padx, pady+2))
		io.write(colour_text("Yes", "green"), "    ", colour_text("No", "red"))
		io.write(cursor_moveto(padx, pady+6))

		local answer = io.read()
		io.write(cursor_moveto(padx, pady+6))
		io.write(cursor_clearline)

		if answer == "y" or answer == "yes" then
			answered_questions[#answered_questions+1] = {active_question.text, colour_text("Yes\n", "green"), active_question.yes_label}
			active_question = active_question.yes
		else 
			answered_questions[#answered_questions+1] = {active_question.text, colour_text("No\n", "red"), active_question.no_label}
			active_question = active_question.no
		end

		if active_question == nil then
			print_answered_questions()
			running = false
		end
	end

end


main()
