using Knet

function dcGinitbn(atype, winit, zsize)
    w1 = winit(4, 4, 512, zsize)
    m1 = bnmoments()
    b1 = bnparams(512)

    w2 = winit(4, 4, 256, 512)
    m2 = bnmoments()
    b2 = bnparams(256)

    w3 = winit(4, 4, 128, 256)
    m3 = bnmoments()
    b3 = bnparams(128)

    w4 = winit(4, 4, 64, 128)
    m4 = bnmoments()
    b4 = bnparams(64)

    w5 = winit(4, 4, 3, 64)

    params = atype.([w1,b1,w2,b2,w3,b3,w4,b4,w5])
    moments = [m1,m2,m3,m4]
    return params, moments
end

function dcDinitbn(atype, winit)
    w1 = winit(4, 4, 3, 64)
    m1 = bnmoments()
    b1 = bnparams(64)

    w2 = winit(4, 4, 64, 128)
    m2 = bnmoments()
    b2 = bnparams(128)

    w3 = winit(4, 4, 128, 256)
    m3 = bnmoments()
    b3 = bnparams(256)

    w4 = winit(4, 4, 256, 512)
    m4 = bnmoments()
    b4 = bnparams(512)

    w5 = winit(4, 4, 512, 1)

    params = atype.([w1,b1,w2,b2,w3,b3,w4,b4,w5])
    moments = [m1,m2,m3,m4]
    return params, moments
end