// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

#let CERG(
  // The paper's title.
  title: "Paper Title",

  // An array of authors. For each author you can specify a name,
  // department, organization, location, and email. Everything but
  // but the name is optional.
  authors: (),
  affiliations: (),

  // The paper's abstract. Can be omitted if you don't have one.
  abstract: none,

  // A list of index terms to display after the abstract.
  keywords: (),

  // The article's paper size. Also affects the margins.
  paper-size: "us-letter",

  // The path to a bibliography file if you want to cite some external
  // works.
  bibliography-file: none,

  // The paper's content.
  body
) = {
  // Set document metadata.
  set document(title: title, author: authors.map(author => author.name))

  show figure.caption: it => {
    set align(left)
    set par(leading: 0.55em, hanging-indent: 0pt, justify: false)
    text(10pt, it)
  }

  // Let figures float
  set figure(placement: auto)

  // show bibliography: set text(7pt)

  // Change table settings
  
  show table.cell.where(y: 0): set text(style: "normal", weight: "bold", size: 9 pt)
  show table.cell: set text(style: "normal", size: 9pt)

  set table(stroke: none)
  
  set table(stroke: (x, y) => (
  left: 0pt,
  right: 0pt,
  top: if y <= 1 { 1pt } else { 0pt },
  bottom: 1pt,
  ))


  // Set the body font.
  set text(font: "Libertinus Serif", size: 12pt)

  // Configure the page.
  set page(
    paper: paper-size,
    // The margins depend on the paper size.
    margin: if paper-size == "a4" {
      (x: 41.5pt, top: 80.51pt, bottom: 89.51pt)
    } else {
      (
        x: (80pt / 216mm) * 100%,
        top: (55pt / 279mm) * 100%,
        bottom: (64pt / 279mm) * 100%,
      )
    }
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  set enum(indent: 10pt, body-indent: 9pt)
  set list(indent: 10pt, body-indent: 9pt)

  // Code
  show raw: set text(font: "Iosevka", rgb("#232323"))

  // Paragraph options
  set par(leading: 1em, first-line-indent: 0pt)
  show heading.where(level: 1): set text(14pt, rgb("#114f54"), font: "Inter", weight: "medium")
  show heading.where(level: 2): set text(13pt, rgb("#2e5385"), font: "Inter", weight: "regular", style: "italic")
  show heading.where(level: 1): it => block(width: 100%)[
    #v(1.2em)
    #block(it.body)
    #v(1em)
  ]
  show heading.where(level: 2): it => block(width: 100%)[
    #block(it.body)
    #v(1em)
  ]

  // Display the paper's title.
  text(18pt, rgb("#1d8265"), weight: "light",  font: "Inter", title)
  v(8.35mm, weak: true)

  show "\@": "@"


  if authors.len() > 0 {
    box(inset: (y: 10pt), {
      authors.map(author => {
        text(12pt, author.name)
        h(1pt)
        if "affiliations" in author {
          super(author.affiliations)
        }
      }).join(", ", last: " and ")
    })
  }
  v(2mm, weak: true)
  if affiliations.len() > 0 {
    box(inset: (y: 12pt), {
      affiliations.map(affiliation => {
        text(12pt, weight: "semibold", super(affiliation.number))
        h(2pt)
        text(12pt, affiliation.name)
      }).join("; ", last: "; ")
    })
  }
  v(2mm, weak: true)
  if authors.len() > 0 {
    box(inset: (y: 10pt), {
      authors.map(author => {
       if "corresponding" in author {
          text(10pt, "Correspondence to ")
          text(10pt, author.name)
          h(5pt)
          sym.dash.em
          h(5pt)
          raw(author.email)
        }
      }).join("")
    })
  }

  v(8.35mm, weak: true)

    // Display abstract and index terms.
  if abstract != none [
    #set par(justify: false, first-line-indent: 0em)
    #set text(weight: 600)
    _Abstract_:
    #set text(weight: 400)
    #abstract

    #if keywords != () [
        #set text(weight: 600)
      _Keywords_: 
      #set text(weight: 400)
      #keywords.join(", ")
    ]
    #v(2pt)
  ]

  v(1cm)

  // Start two column mode and configure paragraph properties.
  // show: columns.with(2, gutter: 14pt)
  set par(justify: true, first-line-indent: 0em, spacing: 1.2em)
  set page(numbering: "1 of 1")

  // Line numbers 
  set par.line(numbering: "1")

  // Display the paper's contents.
  body
}

#show: CERG.with(
  title: "Monitoring biodiversity for human, animal, plant and environmental health",
  abstract: [The One Health approach promotes collaboration across disciplines to enhance the health of humans, animals, plants, and the environment. The Quadripartite organizations, which include the Food and Agriculture Organization of the United Nations (FAO), the United Nations Environment Programme (UNEP), the World Organisation for Animal Health (WOAH), and the World Health Organization (WHO), developed the One Health Joint Plan of Action (OH JPA) to support countries in achieving One Health. This plan consists of six action tracks, each consisting of a set of actions for implementing One Health. By requiring knowledge on zoonotic diseases (tracks 2 and 3), food and agriculture (track 4), antimicrobial resistance (track 5), and environmental health (track 6), most of these tracks directly concern biodiversity. However, there are currently no indicators for monitoring the OH JPA. Our research examines the extent to which all six tracks are covered by the Kunming-Montreal Global Biodiversity Framework (KM-GBF) of the Convention on Biological Diversity (CBD), which contains many indicators at the intersection of biodiversity and health. We assessed (1) the link between each indicator of the KM-GBF and human, animal, plant, and environmental health and (2) the usability of these indicators for monitoring One Health actions. We found that 75% of indicators are associated with health, and that a similar proportion can be used for monitoring One Health actions. Overall, our work aims to strengthen collaboration between the CBD Secretariat and the Quadripartite Organizations by highlighting the need for shared data, policy, and governance practices.

],
    authors: (
                                    (
                    name: "Francis Banville",
                    affiliations: [1],
                    email: "francis.banville\@umontreal.ca",
                                        corresponding: true,
                                        orcid: "0000-0001-9051-0597"
                ),
                                                (
                    name: "Colin Carlson",
                    affiliations: [2],
                    email: "",
                                        orcid: "0000-0001-6960-8434"
                ),
                                                (
                    name: "Elodie Eiffener",
                    affiliations: [3],
                    email: "",
                                        orcid: "0000-0001-5971-4903"
                ),
                                                (
                    name: "Gabriel Munoz Acevedo",
                    affiliations: [4],
                    email: "",
                                        orcid: ""
                ),
                                                (
                    name: "Andrea Paz Velez",
                    affiliations: [1],
                    email: "",
                                        orcid: "0000-0001-6484-1210"
                ),
                                                (
                    name: "Timothée Poisot",
                    affiliations: [1],
                    email: "",
                                        orcid: "0000-0002-0735-5184"
                ),
                        ),
    affiliations: (
                                    (
                    name: "Université de Montréal, Département de sciences biologiques, Montréal Québec, Canada",
                    number: "1",
                ),
                                                (
                    name: "Yale University, Yale School of Public Health, New Haven Connecticut, USA",
                    number: "2",
                ),
                                                (
                    name: "Karolinska Institutet, Stockholm , Sweden",
                    number: "3",
                ),
                                                (
                    name: "Canadian Institute for Health Information, Ottawa Ontario, Canada",
                    number: "4",
                ),
                        ),
  keywords: ("biodiversity indicators", "Kunming-Montreal Global Biodiversity Framework", "One Health", "One Health Joint Plan of Action", "Quadripartite Organizations"),
)

= Introduction
<introduction>
- The One Health approach
  - Interconnection between human, animal, plant, and environmental health
  - Zoonotic diseases, non-communicable diseases, food safety, antimicrobial and antiparasitic resistance, climate change, pollution
  - Collaboration across disciplines
- The One Health Joint Plan of Action
  - Quadripartite Organizations
  - 6 action tracks, many actions, even more activities
  - No indicators
- The Kunming-Montreal Global Biodiversity Framework
  - Convention on Biological Diversity
  - Protecting biodiversity by working towards targets and goals
  - Global Action Plan recognizes that biodiversity is linked with health
- Monitoring framework of the KM-GBF
  - Types of indicators (headline, binary, component, complementary)
  - Many indicators are linked with health (examples)
  - Reusing indicators decreases the workload of countries
- Objectives of our study
  + Assess the link between biodiversity indicators and human, animal, plant, and environmental health

  - Strengthens the link between biodiversity and health
  - Reinforces the need for collaboration across disciplines
  - Highlights the need for shared policy and governance practices between the CBD Secretariat and the Quadripartite Organizations

  #block[
  #set enum(numbering: "1.", start: 2)
  + Evaluate the usability of indicators for monitoring One Health actions
  ]

  - Highlights the need for data sharing between Parties, organizations, and other stakeholders
  - Reduces the workload on countries

= Evaluation of indicators
<evaluation-of-indicators>
- Qualitative assessments
  - Total of 204 indicators
  - Two evaluators for each indicator
  - Assessments based on expert knowledge
  - Finding a consensus between the evaluators

== Assessing the link between biodiversity indicators and health
<assessing-the-link-between-biodiversity-indicators-and-health>
- Qualitative assessments
  - Assessing the link between each indicator and human, animal, plant, and environmental health
  - Direct connection if there is a direct causal relationship between the indicator and health (e.g., the indicator could directly measure the state or a risk factor of health)
  - Indirect connection if there is a single intermediary factor between the indicator and health
  - Potential connection if there are two or more intermediary factors between the indicator and health, or if they are likely connected but we are not sure how
  - No connection if the connection between the indicator and health is far-fetched, unlikely, or absent
  - Require categorizing species and defining health
- Categorizing species within One Health
  - Animals
    - Include pets, livestock, fisheries, and aquaculture, i.e.~species currently looked after by veterinarians and food inspectors
    - Exclude humans and wildlife
    - Are taken care of by the World Organisation for Animal Health (WOAH)
  - Humans
    - Are taken care of by the World Health Organization (WHO)
  - Plants
    - Include species used for food, fuel, and medicine, i.e.~cultivates plants
    - Are taken care of by the Food and Agriculture Organization of the United Nations (FAO)
  - Environment
    - Includes ecosystems and all species not considered in the human, animal, or plant categories
    - Includes forestry and fisheries
    - Being taken care of by the United Nations Environment Programme (UNEP)
- Defining health
  - Human and animal health
    - Overall wellbeing of an individual, i.e.~the extent to which it is able to function physically, mentally, and behaviorally
    - Diseases are deviations from the normal functioning of an individual, often leading to pain, suffering, and death
  - Plant health
    - The extent to which an individual is able to function physically
    - Diseases are deviations from the normal physiological functioning of an individual, often leading to death
  - Environmental health
    - The extent to which the environment is able to function, maintain biological and chemical processes, and adapt to change
    - Disturbances are degradations that lead to a decline in the functioning of ecosystems and biological communities
    - Environmental health include wildlife health

== Assessing the usability of indicators for monitoring the OH JPA
<assessing-the-usability-of-indicators-for-monitoring-the-oh-jpa>
- Qualitative assessments
  - Evaluating each action track independently
  - Identifying the main action that can be monitored for each relevant action track
  - Directly usable indicators can already be used to monitor an action in the action track
  - Indicators usable after adaptation need to be slightly modified (e.g., changes in scale of measurement, data resolution, or taxa) before being used to monitor an action in the action track
  - Not usable indicators need to be greatly modified before being used to monitor the actions in the action track, or they monitor something outside the scope of the action track

= Link between biodiversity indicators and health
<link-between-biodiversity-indicators-and-health>
- Most indicators are linked with health
  - How many indicators are directly or indirectly linked with human, animal, plant, and environmental health?
  - Description of Figure 1
  - Examples of indicator linked with human, animal, plant, and environmental health

#figure([
#box(image("figures/link_health.png"))
], caption: figure.caption(
position: bottom, 
[
Figure caption.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


- Link between biodiversity and health
  - The state of biodiversity impacts health
  - Ecosystem services benefit health
  - Biodiversity and health have similar pressures
  - Biodiversity and health are protected with similar actions

= Usability of indicators for monitoring the OH JPA
<usability-of-indicators-for-monitoring-the-oh-jpa>
- Most indicators can be used to monitor the OH JPA
  - How many indicators for each action track?
  - Description of Table 1
  - Description of Figure 2
  - Importance of directly reusing indicators
  - Indicators usable after adaptation are based on similar and robust methodologies, which minimizing training requirements

#figure([
#box(image("figures/usability_all.png"))
], caption: figure.caption(
position: bottom, 
[
Figure caption.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#figure([
#table(
  columns: (50%, 25%, 25%),
  align: (left,right,right,),
  table.header([Action], [Directly usable], [Usable after adaptation],),
  table.hline(),
  [1.1 Establish the foundations for One Health capacities], [30], [5],
  [1.2 Generate mechanisms, tools, and capacities to establish a One Health competent workforce and the frameworks/processes to facilitate One Health work], [8], [50],
  [1.3 Generate an enabling environment for the effective implementation of One Health], [8], [6],
  [2.1 Understand the drivers of emergence, spillover, and spread of zoonotic pathogens], [16], [27],
  [2.2 Identify and prioritize targeted, evidence-based upstream interventions to prevent the emergence, spillover, and spread of zoonotic pathogens], [7], [6],
  [2.3 Strengthen national, regional, and global One Health surveillance, early warning, and response systems], [17], [30],
  [3.1 Enable countries to develop and implement community-centric and risk-based solutions to endemic zoonotic, neglected tropical, and vector-borne disease control using a One Health approach involving all relevant stakeholders], [3], [14],
  [3.2 Ensure the harmonized application of One Health principles at all levels by implementing practical measures to strengthen local, national, regional, and global policy frameworks for the control and prevention of endemic zoonotic, neglected tropical, and vector-borne diseases], [18], [10],
  [3.3 Increase political commitment and investment in the control of endemic zoonotic, neglected tropical, and vector-borne diseases, by advocating for and demonstrating the value of a One Health approach], [4], [19],
  [4.1 Strengthen the One Health approach in national food control systems and food safety coordination], [18], [30],
  [4.2 Utilize and improve food systems data and analysis, scientific evidence, and risk assessment in developing policy and making integrated risk management decisions], [15], [21],
  [4.3 Foster the adoption of the One Health approach in national foodborne disease surveillance systems and research for the detection and monitoring of foodborne disease and food contamination], [9], [19],
  [5.1 Strengthen the capacity and knowledge of countries to prioritize and implement context-specific collaborative One Health work to control AMR in policy, legislation, and practice], [7], [17],
  [5.2 Reinforce global and regional initiatives and programmes to influence and support One Health responses to AMR], [2], [13],
  [5.3 Strengthen global AMR governance structures], [0], [1],
  [6.1 Protect, restore, and prevent the degradation of ecosystems and the wider environment], [92], [16],
  [6.2 Mainstream the health of the environment and ecosystems into the One Health approach], [9], [7],
  [6.3 Integrate environmental knowledge, data, and evidence into One Health decision-making], [20], [6],
  [6.4 Create an interoperable One Health academic and in-service training programme for environmental, medical, agricultural, and veterinary sector professionals], [5], [7],
)
], caption: figure.caption(
position: top, 
[
Table caption
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-letters>


- Many usable indicators are headline and binary indicators
  - How many?
  - Presentation of important gaps
  - Description of Figure 3
  - Important because these are mandatory indicators that are more likely to be measured

#figure([
#box(image("figures/usability_categories.png"))
], caption: figure.caption(
position: bottom, 
[
Figure caption.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


- Usable indicators are in all categories of the Action Plan
  - The KM-GBF addresses many dimensions of health
  - Presentation of important gaps
  - Description of important categories and their connection with health

#figure([
#box(image("figures/usability_GAP.png"))
], caption: figure.caption(
position: bottom, 
[
Figure caption.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


= Conclusion
<conclusion>
- Monitoring Frameworks
  - The monitoring framework of the OH JPA can be based on indicators of the KM-GBF
  - Importance of reusing indicators to decrease workload on countries
  - Importance of sharing data, methodologies, and expertise
  - Sharing policy and governance practices
- Gaps in indicators
  - Indicators
- Other indicators could be identified in other monitoring frameworks (e.g.~SDG)
  - New indicators can be developed after identifying gaps
