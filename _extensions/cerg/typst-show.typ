#show: CERG.with(
$if(title)$
  title: "$title$",
$endif$
$if(abstract)$
  abstract: [$abstract$],
$endif$
$if(by-author)$
    authors: (
        $for(by-author)$
            $if(it.name.literal)$
                (
                    name: "$it.name.literal$",
                    affiliations: [$for(it.affiliations)$$it.number$$sep$,$endfor$],
                    email: "$it.email$",
                    $if(it.attributes.corresponding)$
                    corresponding: true,
                    $endif$
                    orcid: "$it.orcid$"
                ),
            $endif$
        $endfor$
    ),
$endif$
$if(by-affiliation)$
    affiliations: (
        $for(by-affiliation)$
            $if(it.department)$
                (
                    name: "$it.name$, $it.department$, $it.city$ $it.region$, $it.country$",
                    number: "$it.number$",
                ),
            $else$
                (
                    name: "$it.name$, $it.city$ $it.region$, $it.country$",
                    number: "$it.number$",
                ),
            $endif$
        $endfor$
    ),
$endif$
$if(keywords)$
  keywords: ($for(keywords)$"$it$"$sep$, $endfor$),
$endif$
)
