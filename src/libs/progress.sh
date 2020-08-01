function progressBar()
{
    bar=$(printf "%0.s#" {1..100})
    barlength=100
    n=$(($1*100/$2))
    printf "\r[%-${barlength}s (%d%%)]" "${bar:0:n}" "$n"
}