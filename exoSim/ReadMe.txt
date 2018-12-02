Explications du tableau :
On suppose que D vaut une valeur 'a' inconnue (sur un nombre de bits lui aussi inconnu)
On suppose de même que Q vaut 'b' inconnue.

De plus on se moque de la valeur de H initiale qui est immédiatement fixée à 0. Ainsi H vaudra x au début (sur 1 bit).

A t=0ns, H passe à 0 et le calcul de D = Q+1 commence (et finira à t = 15ns). De plus P2 ne fait rien car il n'y a pas de front montant d'horloge.

A t=10ns, H passe à 1. Ainsi Q prend la valeur de D qui est encore 'a' à cet instant. De plus un nouveau calcul de D = Q+1 commence et finira 15ns plus tard.

A t=15ns, le premier calcul de D termine, D = 'b'+1.

A t=20ns, le front descendant de l'horloge arrive (H=0) et P2 et P3 ne font donc rien.

A t=25ns, le second calcul de D termine écrasant l'ancienne valeur, D = 'a'+1. Il n'y a plus de traces de la valeur initiale de Q.

A t=30ns, H passe à 1, Q prend la valeur de D, c'est à dire 'a'+1. Et le calcul de D = 'a'+2 commence et finira dans 15ns (avant la prochaine sauvegarde)


Ainsi au bout de 30ns, on peut voir que quelque soit les valeurs initiales de H, Q et D, on aboutit bien à un compteur synchrone, dépendant uniquement de la valeur initiale de D.
